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
  String feedKey;

  @override
  String feedName;

  // "local" to access a locally running IC instance
  // "ic" to use canisters on the IC network
  String network;

  // The working directory from which to run the dfx commands (i.e. the
  // directory containing a dfx.json file)
  String dfxWorkingDirectory;

  @override
  String get id => 'internet_computer';

  @override
  void configure(ClonerTaskArgs feedManagerArgs) {
    feedKey = feedManagerArgs.get('key');
    feedName = feedManagerArgs.get('name');
    network = feedManagerArgs.get('network').toLowerCase();
    dfxWorkingDirectory = feedManagerArgs.get('dfxWorkingDirectory');
  }

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
    if (stderr.isNotEmpty) {
      throw stderr;
    }

    if (stdout == '(null)\n') {
      // No feed found with the given name
      return false;
    }

    feed = fromCandidString(stdout);

    return true;
  }

  @override
  Future<void> write() async {
    final feedCandidString = toCandidString(feed);

    final args = [
      'canister',
      '--network',
      '$network',
      'call',
      'serve',
      'addFeed',
      '("$feedKey", $feedCandidString)'
    ];
    final output =
        await processRunner('dfx', args, workingDirectory: dfxWorkingDirectory);

    final stderr = output.stderr;
    if (stderr.isNotEmpty) {
      throw stderr;
    }

    final stdout = output.stdout;

    if (stdout == '(null)\n)') {
      // No feed found with the given name
      return false;
    }

    return true;
  }

  static String toCandidString(Feed feed) {
    String escape(String str) => str.replaceAll('\"', '\\\"');

    final mediaListCandid = feed.mediaList.map((servedMedia) => '''
    record { 
      etag="${escape(servedMedia.etag)}";
      lengthInBytes=${servedMedia.lengthInBytes};
      uri="${servedMedia.uri}";
      title="${escape(servedMedia.media.title)}";
      description="${escape(servedMedia.media.description)}";
      durationInMicroseconds=${servedMedia.media.duration.inMicroseconds};
      source=record {
        id="${servedMedia.media.source.id}";
        uri="${servedMedia.media.source.uri}";
        releaseDate="${servedMedia.media.source.releaseDate}";
        platform=record {
          id="${servedMedia.media.source.platform.id}";
          uri="${servedMedia.media.source.platform.uri}"
        }
      };
    }''').join('; ');

    final candid = '''
record { 
  title="${escape(feed.title)}";
  subtitle="${escape(feed.subtitle)}";
  description="${escape(feed.description)}";
  link="${feed.link}";
  author="${escape(feed.author)}";
  email="${feed.email}";
  imageUrl="${feed.imageUrl}";
  mediaList=vec {
$mediaListCandid
  };
}''';
    return candid;
  }

  static Feed fromCandidString(String candid) {
    final recordValue = parseCandid(candid).value;
    if (!(recordValue is RecordValue)) {
      throw 'Encountered non-record at the start of candid: $candid';
    }
    final record = (recordValue as RecordValue).record;
    final mediaListAsRecordValues = getVector(record['mediaList']);
    final mediaList = mediaListAsRecordValues.map(
      (mediaRecordValue) => ServedMedia(
        (s) => s
          ..etag = getString(mediaRecordValue, ['etag'], 'abcdefghijkl')
          ..lengthInBytes =
              getNumber(mediaRecordValue, ['lengthInBytes'], 0).ceil()
          ..uri = Uri.parse(getString(mediaRecordValue, ['uri']))
          ..media = Media(
            (m) => m
              ..title = getString(mediaRecordValue, ['title'])
              ..description = getString(mediaRecordValue, ['description'])
              ..duration = Duration(
                  microseconds:
                      getNumber(mediaRecordValue, ['durationInMicroseconds'], 0)
                          .ceil())
              ..source = Source((s) => s
                ..id = getString(mediaRecordValue, ['source', 'id'])
                ..uri =
                    Uri.parse(getString(mediaRecordValue, ['source', 'uri']))
                ..releaseDate = DateTime.parse(getString(mediaRecordValue,
                    ['source', 'releaseDate'], '1970-01-01T00:00:00.000Z'))
                ..platform = Platform((p) => p
                  ..id =
                      getString(mediaRecordValue, ['source', 'platform', 'id'])
                  ..uri = Uri.parse(getString(mediaRecordValue,
                      ['source', 'platform', 'uri']))).toBuilder()).toBuilder(),
          ).toBuilder(),
      ),
    );

    return Feed((f) => f
      ..title = getString(record['title'])
      ..subtitle = getString(record['subtitle'])
      ..description = getString(record['description'])
      ..link = getString(record['link'])
      ..author = getString(record['author'])
      ..email = getString(record['email'])
      ..imageUrl = getString(record['imageUrl'])
      ..mediaList = BuiltList<ServedMedia>(mediaList).toBuilder());
  }

  static String getString(CandidValue candidValue,
      [List<String> path, String defaultValue]) {
    String unescape(String str) => str.replaceAll('\\\"', '\"');

    if (candidValue is StringValue) {
      return candidValue.string;
    }
    if (candidValue == null) {
      throw 'Null CandidValue';
    }
    if (!(candidValue is RecordValue)) {
      throw 'Can only get a string from a StringValue or a RecordValue with a path to a StringValue';
    }
    final lastKey = path.removeLast();
    final terminalRecord = getRecord(candidValue, path);
    if (!terminalRecord.containsKey(lastKey)) {
      throw 'Key not found: $lastKey';
    }
    candidValue = terminalRecord[lastKey];
    if (candidValue is StringValue) {
      return unescape(candidValue.string);
    }
    throw 'Value is not a StringValue';
  }

  static double getNumber(CandidValue candidValue,
      [List<String> path, double defaultValue]) {
    if (candidValue is NumberValue) {
      return candidValue.number;
    }
    if (candidValue == null) {
      throw 'Null CandidValue';
    }
    if (!(candidValue is RecordValue)) {
      throw 'Can only get a number from a NumberValue or a RecordValue with a path to a NumberValue';
    }
    final lastKey = path.removeLast();
    final terminalRecord = getRecord(candidValue, path);
    if (!terminalRecord.containsKey(lastKey)) {
      print('Key not found: $lastKey');
      return defaultValue;
      // throw 'Key not found: $lastKey';
    }
    candidValue = terminalRecord[lastKey];
    if (candidValue is NumberValue) {
      return candidValue.number;
    }
    throw 'Value is not a NumberValue';
  }

  static List<RecordValue> getVector(CandidValue candidValue,
      [List<String> path]) {
    if (candidValue is VectorValue) {
      return candidValue.vector;
    }
    if (!(candidValue is RecordValue)) {
      throw 'Can only get a vector from a VectorValue or a RecordValue with a path to a VectorValue';
    }
    final lastKey = path.removeLast();
    final terminalRecord = getRecord(candidValue, path);
    candidValue = terminalRecord[lastKey];
    if (candidValue is VectorValue) {
      return candidValue.vector;
    }
    throw 'Value is not a VectorValue';
  }

  static Map<String, CandidValue> getRecord(RecordValue recordValue,
      [List<String> path]) {
    if (recordValue == null) {
      throw 'Cannot get record from a null RecordValue';
    }
    if (path == null || path.isEmpty) {
      return recordValue.record;
    }
    for (var key in path) {
      if (!(recordValue is RecordValue)) {
        throw 'Encountered non-record value in path';
      }
      if (!recordValue.record.containsKey(key)) {
        throw 'Record does not contain key "$key"';
      }
      recordValue = recordValue.record[key];
    }
    if (recordValue is RecordValue) {
      return recordValue.record;
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

    final key = match.group(1);
    final rest = match.group(2);

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

    final str = match.group(1);
    final rest = match.group(2);
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

    final str = match.group(1).replaceAll('_', '');
    final rest = match.group(3);

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
      } else {
        return str;
      }
    });
    return str;
  }
}
