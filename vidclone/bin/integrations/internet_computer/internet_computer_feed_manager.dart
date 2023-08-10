import 'dart:math';
import 'package:vidlib/vidlib.dart';
import '../../feed_manager.dart';
import 'package:built_collection/built_collection.dart';
import 'package:quiver/core.dart';
import 'package:collection/collection.dart';

class CandidValue {}

class EntryValue extends CandidValue {
  final String key;
  final CandidValue value;
  EntryValue(this.key, this.value);

  @override
  bool operator ==(Object x) =>
      (x is EntryValue && x.key == key && x.value == value);

  @override
  int get hashCode => hash2(key.hashCode, value.hashCode);
}

class NumberValue extends CandidValue {
  final double number;
  NumberValue(this.number);

  @override
  bool operator ==(Object x) => (x is NumberValue && x.number == number);

  @override
  int get hashCode => number.hashCode;
}

class StringValue extends CandidValue {
  final String string;
  StringValue(this.string);

  @override
  bool operator ==(Object x) => (x is StringValue && x.string == string);

  @override
  int get hashCode => string.hashCode;
}

class RecordValue extends CandidValue {
  // A map of the record's keys to their values. Values might be simple
  // strings, other records or vectors of records.
  final Map<String, CandidValue> record;
  RecordValue(this.record);

  @override
  bool operator ==(Object x) =>
      (x is RecordValue && MapEquality().equals(x.record, record));

  @override
  int get hashCode => MapEquality().hash(record);
}

class VectorValue extends CandidValue {
  final List<RecordValue> vector;
  VectorValue(this.vector);

  @override
  bool operator ==(Object x) =>
      (x is VectorValue && ListEquality().equals(x.vector, vector));

  @override
  int get hashCode => hashObjects(vector);
}

class CandidResult<V extends CandidValue> {
  final V value;
  final String remainingCandid;
  CandidResult(this.value, this.remainingCandid);

  @override
  bool operator ==(Object x) => (x is CandidResult &&
      x.value == value &&
      x.remainingCandid == remainingCandid);

  @override
  int get hashCode => hash2(value.hashCode, remainingCandid.hashCode);
}

// Manages a feed running on dfinity's Internet Computer (https://dfinity.org/)
class InternetComputerFeedManager extends FeedManager {
  late String feedKey;

  @override
  late String feedName;

  // The owner principal for all feeds created through this FeedManager
  late String owner;

  // "local" to access a locally running IC instance "ic" to use canisters on
  // the IC network
  late String network;

  // The working directory from which to run the dfx commands (i.e. the
  // directory containing a dfx.json file)
  late String dfxWorkingDirectory;

  // The EpisodeIds for the Episodes in this FeedManager's Feed. These IDs
  // reference actual Episodes on the IC, so feed.mediaList will have more
  // items than episodeIds until "write" is called when the Episodes will be
  // created on the IC and this list will be updated to reference the newly
  // created Episodes
  List<int> episodeIds = [];

  // The SourceID (unique identifier on source platform, e.g. the unique part
  // of the YouTube URL) of the most recent episode on the feed as it exists on
  // the Internet Computer. This is used to determine which episodes need to be
  // written to the feed, as only episodes after this one need to be added.
  String? mostRecentMediaSourceId;

  @override
  String get id => 'internet_computer';

  @override
  void configure(ClonerTaskArgs feedManagerArgs) {
    feedKey = feedManagerArgs.get('key');
    feedName = feedManagerArgs.get('name');
    owner = feedManagerArgs.get('owner');
    network = feedManagerArgs.get('network').toLowerCase();
    dfxWorkingDirectory = feedManagerArgs.get('dfxWorkingDirectory');
  }

  /* 
getFeed:
  (
  opt record { key = "test"; title = "Test Feed"; owner = principal
    "m5wvb-yrvsf-dv5em-uotcy-nvu2e-maoes-hgboi-6dpxr-m4wv4-aer2n-fqe"; link =
    "http://www.test.com"; description = "A Test Feed"; email =
    "tom@example.com"; author = "Tom Merritt"; episodeIds = vec { 0 : nat };
    imageUrl =
    "https://s3.amazonaws.com/creare-websites-wpms-legacy/wp-content/uploads/sites/32/2016/03/01200959/canstockphoto22402523-arcos-creator.com_-1024x1024.jpg";
    subtitle = "test subtitle";
  },
)



  */

  @override
  Future<bool> populate() async {
    final args = [
      'canister',
      '--network',
      '$network',
      'call',
      'serve',
      'getFeed',
      '("$feedName")'
    ];
    final output =
        await processRunner('dfx', args, workingDirectory: dfxWorkingDirectory);

    final stdout = output.stdout;

    final stderr = output.stderr;
    if (stderr.toString().toLowerCase().contains('error')) {
      throw stderr;
    }

    if (stdout == '(null)\n') {
      // No feed found with the given name
      return false;
    }

    feed = fromCandidString(stdout);
    episodeIds = getEpisodeIds(stdout);

    if (episodeIds.isNotEmpty) {
      final mostRecentEpisodeId = episodeIds.last;

      // Get most recent episode
      final mostRecentEpisode = await runDfxCommand(
          'getEpisode', '("$feedKey", $mostRecentEpisodeId)');

      // Get mediaId from episode
      var regExp = RegExp(
        r'mediaId = (\d+) : nat;',
        caseSensitive: false,
        multiLine: true,
      );
      var mostRecentMediaIdString = regExp
          .firstMatch(mostRecentEpisode)?[1]; // Null implies no mediaId found
      print('mostRecentMediaIdString: ' +
          (mostRecentMediaIdString ?? 'not found'));

      if (mostRecentMediaIdString != null) {
        var mostRecentMediaId = int.parse(mostRecentMediaIdString);

        // Get most recent media
        final mostRecentMedia =
            await runDfxCommand('getMedia', '$mostRecentMediaId');

        // Get source id. That's what we'll match on since it's more likely to
        // be unique than, e.g, the title
        regExp = RegExp(
          r'id = "(.*)";', // This may fail since other lines use this format, but the source should be the first
          caseSensitive: false,
          multiLine: true,
        );
        mostRecentMediaSourceId = regExp
            .firstMatch(mostRecentMedia)?[1]; // Null implies no sourceId found
        print('mostRecentSourceId: $mostRecentMediaSourceId');

        // Now we have mostRecentEpisodeSourceId saved, which will be used on
        // Write to make sure we only create and add Episodes *after* it
      }
    }

    return true;
  }

  @override
  Future<void> write() async {
    // First update the Feed. Note that this won't add any new Episodes;
    // they'll stay the same as what was returned in Populate. We'll add
    // Episodes next, but this call will update the feed with any other
    // modified data, like the title or description. It will also create the
    // feed if it doens't yet exist.
    final feedCandid = feedToCandidString(feedKey, feed, episodeIds, owner);
    final putFeedResult = await runDfxCommand('putFeed', '($feedCandid)');
    // print(putFeedResult);

    // Create any newly added Episodes
    var startIndex = 0;

    // Find the most recent media in mediaList with the same source id. This
    // may cause issues if the same video is in the feed multiple times, but
    // that should be rare and would only cause a problem if the cloning
    // hadn't been run after cloning the first duplicated video but before
    // cloning the video after it (so the duplicated video is the most recent
    // video), and also after the other duplicate was added to the source
    // feed.
    for (var i = feed.mediaList.length - 1; i >= 0; i--) {
      final servedMedia = feed.mediaList[i];
      if (servedMedia.media.source.id == mostRecentMediaSourceId) {
        startIndex = i + 1; // Start after the one we found
        break;
      }
    }

    // Create Episodes for each newly added Media
    for (var i = startIndex; i < feed.mediaList.length; i++) {
      final servedMedia = feed.mediaList[i];

      final mediaCandid = mediaToCandidString(servedMedia, owner);

      // Submit the Media to receive the MediaID, which we need for the Episode
      final addMediaResult = await runDfxCommand('addMedia', '($mediaCandid)');
      //print('Added media.');
      //print(addMediaResult);

      // Get the MediaID for the newly added Media
      var regExp = RegExp(
        r'id = (\d*) \: nat;',
        caseSensitive: false,
        multiLine: true,
      );
      var mediaIdString = regExp.firstMatch(addMediaResult)![1]!;
      print('Added mediaId $mediaIdString. title: ${servedMedia.media.title}');
      var mediaId = int.parse(mediaIdString);

      // Create the Episode. This also updates the Episode list on the IC Feed.
      final episodeCandid =
          episodeToCandidString(feedKey, servedMedia, mediaId);
      final addEpisodeResult = await runDfxCommand('addEpisode', episodeCandid);
      print('Added episode. Result:');
      print(addEpisodeResult);

      // Get the EpisodeId for the newly added Episode so we can update our
      // local list
      regExp = RegExp(
        r'id = (\d*) \: nat;',
        caseSensitive: false,
        multiLine: true,
      );
      var episodeIdString = regExp.firstMatch(addEpisodeResult)![1]!;
      print(
          'Added episode $episodeIdString. Title: ${servedMedia.media.title}');
      var episodeId = int.parse(episodeIdString);

      print('adding episodeId $episodeId');

      // Add the Episode's ID to our list
      episodeIds.add(episodeId);

      // Store the SourceId so we know where to start on the next call to Write
      mostRecentMediaSourceId = servedMedia.media.source.id;
    }

    print('Done with write');
  }

  // // Extract the list of numberical EpisodeIDs in the given feed candid
  // List<int> getEpisodeIds(String feedCandid) {
  //   // Find all the text between "episodeIds = vec {" and the next closing
  //   // parenthesis. This will include the entire list of numbers.
  //   var regExp = RegExp(
  //     r'episodeIds = vec {([^}]*)}',
  //     caseSensitive: false,
  //     multiLine: true,
  //   );
  //   var fullCandidVec = regExp.firstMatch(feedCandid)?[1] ?? 'EMPTY';

  //   if (fullCandidVec == 'EMPTY') {
  //     return [];
  //   } else {
  //     // We found a list. Now extract all the numbers.
  //     regExp = RegExp(
  //       r'\d+',
  //       caseSensitive: false,
  //       multiLine: true,
  //     );
  //     var matches = regExp.allMatches(fullCandidVec);

  //     return matches
  //         .map((regExpMatch) => int.parse(regExpMatch.group(0)!))
  //         .toList();
  //   }
  // }

  Future<String> runDfxCommand(String command, String arg) async {
    final args = [
      'canister',
      '--network',
      '$network',
      'call',
      'serve',
      '$command',
      '$arg'
    ];
    final output =
        await processRunner('dfx', args, workingDirectory: dfxWorkingDirectory);

    final stderr = output.stderr;
    if (stderr.isNotEmpty) {
      if (!stderr.toString().startsWith('WARN:')) {
        throw stderr;
      }
    }

    final stdout = output.stdout;
    if (output.stdout.contains('err')) {
      // If the candid returned contains an error, throw it. Returned candid
      // comes back on stdout, not stderr.

      if (output.stdout.contains('ContributorsError') &&
          output.stdout.contains('NotFound')) {
        print(
            'Cannot execute command $command because a specified principal was not found. Check that all Contributors exist on the correct network ($network) or switch networks (IC/Local).');
      }
      throw output.stdout;
    }

    return stdout;

    // if (stdout == '(null)\n)') { // No feed found with the given name return
    //   false;
    // }
  }

  static String escape(String str) => str.replaceAll('\"', '\\\"');

  static String mediaToCandidString(ServedMedia servedMedia, String owner) {
    return '''
    record { 
      etag="${escape(servedMedia.etag)}";
      lengthInBytes=${servedMedia.lengthInBytes};
      uri="${servedMedia.uri}";
      description="${escape(servedMedia.media.description)}";
      durationInMicroseconds=${servedMedia.media.duration.inMicroseconds};

      resources=vec {record {weight=1; resource=variant {individual=principal "$owner"}}};

      source=record {
        id="${servedMedia.media.source.id}";
        uri="${servedMedia.media.source.uri}";
        releaseDate="${servedMedia.media.source.releaseDate}";
        platform=record {
          id="${servedMedia.media.source.platform.id}";
          uri="${servedMedia.media.source.platform.uri}"
        }
      };
    }''';
  }

  static String episodeToCandidString(
      String feedKey, ServedMedia servedMedia, int mediaId) {
    return '''
    record { 
      feedKey="$feedKey";
      title="${escape(servedMedia.media.title)}";
      description="${escape(servedMedia.media.description)}";
      mediaId=$mediaId; 
    }''';
  }

  static String feedToCandidString(
      String key, Feed feed, List<int> episodeIds, String owner) {
    final episodeIdsCandid = episodeIds.join('; ');

    // final mediaListCandid = feed.mediaList.map((servedMedia) => ''' record {
    // etag="${escape(servedMedia.etag)}";
    // lengthInBytes=${servedMedia.lengthInBytes}; uri="${servedMedia.uri}";
    // title="${escape(servedMedia.media.title)}";
    // description="${escape(servedMedia.media.description)}";
    // durationInMicroseconds=${servedMedia.media.duration.inMicroseconds};
    // resources=vec{}; source=record { id="${servedMedia.media.source.id}";
    // uri="${servedMedia.media.source.uri}";
    // releaseDate="${servedMedia.media.source.releaseDate}"; platform=record {
    // id="${servedMedia.media.source.platform.id}";
    // uri="${servedMedia.media.source.platform.uri}"
    //     }
    //   };
    // }''').join('; ');

    final candid = '''
record { 
  key="$key";
  title="${escape(feed.title)}";
  subtitle="${escape(feed.subtitle)}";
  description="${escape(feed.description)}";
  link="${feed.link}";
  author="${escape(feed.author)}";
  owner=principal \"$owner\";
  email="${feed.email}";
  imageUrl="${feed.imageUrl}";
  episodeIds=vec {
$episodeIdsCandid
  };
}''';
    return candid;
  }

  static RecordValue getRecordValue(String candid) {
    final recordValue = parseCandid(candid).value;
    if (!(recordValue is RecordValue)) {
      throw 'Encountered non-record at the start of candid: $candid';
    }
    return recordValue;
  }

  static Feed fromCandidString(String candid) {
    final record = getRecordValue(candid).record;

    return Feed((f) => f
      ..title = getString(record['title']!)
      ..subtitle = getString(record['subtitle']!)
      ..description = getString(record['description']!)
      ..link = getString(record['link']!)
      ..author = getString(record['author']!)
      ..email = getString(record['email']!)
      ..imageUrl = getString(record['imageUrl']!));
  }

  // The Feed type in Dart does not include EpisodeIds even though the Feed
  // type on the IC does, so we have to parse that separately since it isn't
  // returned by fromCandidString
  static List<int> getEpisodeIds(String candid) {
    final record = getRecordValue(candid).record;
    return getVector(record['episodeIds']!) as List<int>;
  }

  static String getString(CandidValue candidValue,
      [List<String>? path, String? defaultValue]) {
    String unescape(String str) => str.replaceAll('\\\"', '\"');

    if (candidValue is StringValue) {
      return candidValue.string;
    }
    if (!(candidValue is RecordValue && path != null && path.isNotEmpty)) {
      throw 'Can only get a string from a StringValue or a RecordValue with a path to a StringValue';
    }
    final lastKey = path.removeLast();
    final terminalRecord = getRecord(candidValue, path);
    if (!terminalRecord.containsKey(lastKey)) {
      throw 'Key not found: $lastKey';
    }

    candidValue = terminalRecord[lastKey]!;

    if (candidValue is StringValue) {
      return unescape(candidValue.string);
    }
    throw 'Value is not a StringValue';
  }

  static double getNumber(CandidValue candidValue,
      [List<String>? path, double? defaultValue]) {
    if (candidValue is NumberValue) {
      return candidValue.number;
    }
    if (!(candidValue is RecordValue && path != null && path.isNotEmpty)) {
      throw 'Can only get a number from a NumberValue or a RecordValue with a path to a NumberValue';
    }
    final lastKey = path.removeLast();
    final terminalRecord = getRecord(candidValue, path);
    if (!terminalRecord.containsKey(lastKey)) {
      print('Key not found: $lastKey');
      if (defaultValue != null) {
        return defaultValue;
      }
      throw 'Key not found: $lastKey and no default value provided';
    }
    candidValue = terminalRecord[lastKey]!;
    if (candidValue is NumberValue) {
      return candidValue.number;
    }
    throw 'Value is not a NumberValue';
  }

  static List<RecordValue> getVector(CandidValue candidValue,
      [List<String>? path]) {
    if (candidValue is VectorValue) {
      return candidValue.vector;
    }
    if (!(candidValue is RecordValue && path != null && path.isNotEmpty)) {
      throw 'Can only get a vector from a VectorValue or a RecordValue with a path to a VectorValue';
    }
    final lastKey = path.removeLast();
    final terminalRecord = getRecord(candidValue, path);
    final terminalValue = terminalRecord[lastKey];
    if (terminalValue is VectorValue) {
      return terminalValue.vector;
    }
    throw 'Value is not a VectorValue';
  }

  static Map<String, CandidValue> getRecord(RecordValue recordValue,
      [List<String>? path]) {
    if (path == null || path.isEmpty) {
      return recordValue.record;
    }
    for (var key in path) {
      if (!recordValue.record.containsKey(key)) {
        throw 'Record does not contain key "$key"';
      }
      var valueAtKey = recordValue.record[key]!;

      if (!(valueAtKey is RecordValue)) {
        throw 'Encountered non-record value in path';
      }

      recordValue = valueAtKey;
    }
    throw 'Value is not a RecordValue';
  }

  static const stringSignifier = '"';
  static const recordSignifier = 'record {';
  static const vectorSignifier = 'vec {';

  static String removeUnnecessaryLeadingCandid(String candid) {
    var c = candid.trimLeft();
    if (c.startsWith('(')) {
      c = c.substring(c.indexOf('(') + 1).trimLeft();
    }
    if (c.startsWith('opt ')) {
      c = c.substring(c.indexOf('opt ') + 4).trimLeft();
    }
    return c;
  }

  // Recursive function that, given a candid string, returns a result
  // representing the records and values within.
  static CandidResult parseCandid(String candid) {
    var sanitizedCandid = removeUnnecessaryLeadingCandid(candid);

    // Figure out what we're about to parse based on which signifier comes
    // first
    final firstRecord = sanitizedCandid.indexOf(recordSignifier);
    final firstVector = sanitizedCandid.indexOf(vectorSignifier);
    final firstEntry = sanitizedCandid.indexOf('=');
    final firstString = sanitizedCandid.indexOf(stringSignifier);
    final firstNumber = sanitizedCandid.indexOf(RegExp(r'^\d'));

    // Find the first of those
    final first = [
      firstRecord,
      firstVector,
      firstEntry,
      firstString,
      firstNumber
    ].where((element) => element >= 0).reduce(min);

    if (firstRecord == first) {
      // Record
      return parseCandidAsRecord(sanitizedCandid);
    } else if (firstVector == first) {
      // Vector
      return parseCandidAsVector(sanitizedCandid);
    } else if (firstEntry == first) {
      // Entry
      return parseCandidAsEntry(sanitizedCandid);
    } else if (firstString == first) {
      // String
      return parseCandidAsString(sanitizedCandid);
    } else if (firstNumber == first) {
      // Number
      return parseCandidAsNumber(sanitizedCandid);
    } else {
      throw 'Unable to parse line starting with ${sanitizedCandid.substring(20)}';
    }
  }

  static CandidResult<EntryValue> parseCandidAsEntry(String candid) {
    final match =
        RegExp(r'^\s*(\w+)\s*=\s*(.*$)', dotAll: true).firstMatch(candid);
    if (match == null) {
      throw ('Candid string does not begin with an entry. '
          'Candid starts with: ${candid.substring(0, 50)}');
    }

    final key = match.group(1)!;
    final rest = match.group(2)!;

    final valueResult = parseCandid(rest);
    if (valueResult.value is EntryValue) {
      throw ('Invalid: Found an entry as the value of another entry.');
    }
    return CandidResult(
        EntryValue(key, valueResult.value), valueResult.remainingCandid);
  }

  static CandidResult<StringValue> parseCandidAsString(String candid) {
    if (!candid.startsWith('"')) {
      throw ('Cannot parse candid as a string when the candid does not start '
          'with double quotes. Candid begins with: ${candid.substring(10)}');
    }
    // Select everything after the first quote and before the next quote,
    // ignoring escaped quotes. Also select the rest (throwing out a semicolon
    // and any whitespace at the end if found) to pass along with the result
    final match = RegExp(
      r'"(.*?)(?<!\\)"\s*[ ;]\s*(.*$)',
      dotAll: true,
    ).firstMatch(candid);
    if (match == null) {
      throw ('Failed to find string in candid. Must be surrounded by non-'
          'escaped double quotes followed by a semicolon. Candid: $candid');
    }

    final str = match.group(1)!;
    final rest = match.group(2)!;
    return CandidResult(StringValue(str), rest);
  }

  static CandidResult<NumberValue> parseCandidAsNumber(String candid) {
    if (!candid.startsWith(RegExp(r'\d'))) {
      throw ('Cannot parse candid as a number when the candid does not start '
          'with a number. Candid begins with: ${candid.substring(10)}');
    }
    // Select everything that is either a digit, an underscore or a decimal.
    // Also select the rest (throwing out a semicolon and any whitespace at the
    // end if found) to pass along with the result
    final match = RegExp(
      r'([\d_\.]+)( : nat)?;?\s*(.*$)',
      dotAll: true,
    ).firstMatch(candid);
    if (match == null) {
      throw ('Failed to find number in candid. Candid: $candid');
    }

    final str = match.group(1)!.replaceAll('_', '');
    final rest = match.group(3)!;

    final num = double.parse(str);

    return CandidResult(NumberValue(num), rest);
  }

  static CandidResult<RecordValue> parseCandidAsRecord(String candid) {
    if (!candid.trimLeft().startsWith(recordSignifier)) {
      throw ('Candid is not a record. Candid begins with: ${candid.substring(0, 50)}');
    }
    final record = <String, CandidValue>{};
    var remainingCandid = candid
        .substring(candid.indexOf(recordSignifier) + recordSignifier.length);
    while (remainingCandid.trimLeft().isNotEmpty) {
      final entryResult = parseCandid(remainingCandid);
      if (!(entryResult.value is EntryValue)) {
        throw 'Non-entry item found in candid record: $remainingCandid';
      }

      final entry = entryResult.value as EntryValue;

      // Add the entry
      record[entry.key] = entry.value;

      remainingCandid = entryResult.remainingCandid;
      if (remainingCandid.trimLeft().startsWith('}')) {
        // This is the end of the record. We need to figure out how much else
        // to remove before we return the record, which varies depending on
        // whether the record was in a vector or not.

        // Records in vectors end in ; or };
        remainingCandid = removeLeading(remainingCandid, ['}', ';']);

        // Single records end in , or ). We'll have already removed the end
        // curly brace from the call above.
        remainingCandid = removeLeading(remainingCandid, [',', ')']);

        return CandidResult(RecordValue(Map<String, CandidValue>.from(record)),
            remainingCandid);
      }
    }

    throw 'Reached end of candid record without encountering closing brace';
  }

  static CandidResult<VectorValue> parseCandidAsVector(String candid) {
    if (!candid.trimLeft().startsWith(vectorSignifier)) {
      throw ('Candid is not a vector. Candid begins with: ${candid.substring(10)}');
    }
    final vector = [];
    var remainingCandid = candid
        .substring(candid.indexOf(vectorSignifier) + vectorSignifier.length);

    while (remainingCandid.trimLeft().isNotEmpty) {
      if (remainingCandid.trimLeft().startsWith('}')) {
        remainingCandid = removeLeading(remainingCandid, ['}', ';']);
        return CandidResult(
            VectorValue(List<RecordValue>.from(vector)), remainingCandid);
      }

      final recordResult = parseCandid(remainingCandid);
      if (!(recordResult.value is RecordValue)) {
        throw 'Non-record item found in candid vector: $remainingCandid';
      }

      final recordValue = recordResult.value as RecordValue;

      // Add the entry
      vector.add(recordValue);

      remainingCandid = recordResult.remainingCandid;
    }

    throw 'Reached end of candid vector without encountering closing bracket';
  }

  // Removes tokens from the beginning of the string, one at a time in order,
  // stopping as soon as one isn't found
  static String removeLeading(String str, List<String> tokens) {
    tokens.forEach((token) {
      if (str.trimLeft().startsWith(token)) {
        str = str.substring(str.indexOf(token) + token.length);
      }
    });
    return str;
  }
}
