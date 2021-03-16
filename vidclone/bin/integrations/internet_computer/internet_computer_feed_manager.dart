import 'package:vidlib/vidlib.dart' hide Platform;
import '../../feed_manager.dart';

// Manages a feed running on dfinity's Internet Computer (https://dfinity.org/)
class InternetComputerFeedManager extends FeedManager {
  String feedKey;

  // True to access a locally running IC instance, False to use canisters on
  // the IC network
  bool localIC;

  // The working directory from which to run the dfx commands (i.e. the
  // directory containing a dfx.json file)
  String dfxWorkingDirectory;

  @override
  String get id => 'internet_computer';

  @override
  String get feedName => feedKey;

  @override
  void configure(ClonerTaskArgs feedManagerArgs) {
    feedKey = feedManagerArgs.get('feedName');
    localIC = feedManagerArgs.get('localIC').toLowerCase() == 'true';
    dfxWorkingDirectory = feedManagerArgs.get('dfxWorkingDirectory');
  }

  @override
  Future<bool> populate() async {
    final List<String> network = localIC ? [] : ['--network', 'ic'];
    final args = [
      'canister',
      ...network,
      'call',
      'credits',
      'getFeed',
      '("$feedName")'
    ];
    final output =
        await processRunner('dfx', args, workingDirectory: dfxWorkingDirectory);

    final stdout = output.stdout;

    if (stdout == '(null)\n)') {
      // No feed found with the given name
      return false;
    }

    return false;
  }

  @override
  Future<void> write() async {
    final feedCandidString = toCandidString(feed);

    final List<String> network = localIC ? [] : ['--network', 'ic'];
    final args = [
      'canister',
      ...network,
      'call',
      'serve',
      'addFeed',
      '("$feedName", $feedCandidString)'
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

  String toCandidString(Feed feed) {
    final mediaListCandid = feed.mediaList.map((servedMedia) => '''
    record { 
      uri="${servedMedia.uri}"; 
      title="${servedMedia.media.title}"; 
      source=record { 
        id="${servedMedia.media.source.id}"; 
        uri="${servedMedia.media.source.uri}"; 
        platform=record { 
          id="${servedMedia.media.source.platform.id}"; 
          uri="${servedMedia.media.source.platform.uri}"
        } 
      }; 
      description="${servedMedia.media.description}"
    }''').join(',');

    final candid = '''
record { 
  title="${feed.title}"; 
  link="http://example.com"; 
  description="${feed.description}"; 
  email="${feed.email}"; 
  author="${feed.author}"; 
  imageUrl="${feed.imageUrl}"; 
  mediaList=vec { 
$mediaListCandid
  }; 
  subtitle="Powered by Videate" 
}''';
    return candid;
  }
}
