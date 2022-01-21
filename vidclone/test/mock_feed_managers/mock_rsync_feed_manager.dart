import 'dart:io';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:vidlib/vidlib.dart';
import '../../bin/integrations/rsync/rsync_feed_manager.dart';

class MockRsyncFeedManager extends RsyncFeedManager {
  @override
  String get id => 'rsync';

  @override
  String get endpointUrl => 'https://example.com';

  // Store the pushed feed locally instead of pushing it via rsync
  Feed pushedFeed;

  MockRsyncFeedManager() : super() {
    // The default client avoids http calls by returning the feed that was most
    // recently pushed, or null if nothing has been pushed this run.
    client = MockClient((request) async {
      if (pushedFeed == null) {
        return Response('', 404);
      }

      final json = pushedFeed.toJson().toString();
      return Response(json, 200, headers: {
        'etag': 'a1b2c3',
        'content-length': json.length.toString()
      });
    });
  }

  // Instead of running the rsync command, this process runner caches the feed
  // specified in the arguments so it can be retrieved by calls to populate()
  @override
  ProcessResult Function(String executable, List<String> arguments)
      get processRunner => (String executable, List<String> arguments) {
            // The file path should be the fourth argument
            final filePath = arguments[3];
            final file = File(filePath);
            final json = file.readAsStringSync();
            final feed = Feed.fromJson(json);

            pushedFeed = feed;

            return ProcessResult(0, 0, '', '');
          };
}
