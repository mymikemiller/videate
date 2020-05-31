import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import '../bin/integrations/local/json_file_feed_manager.dart';
import 'package:path/path.dart' as p;
import '../bin/feed_manager.dart';

final memoryFileSystem = MemoryFileSystem();

class FeedManagerTest {
  final FeedManager feedManager;

  FeedManagerTest(this.feedManager);
}

void main() async {
  final feedManagerTests = [
    FeedManagerTest(await JsonFileFeedManager.createOrOpen(
        p.join(memoryFileSystem.systemTempDirectory.path, 'feed.json'),
        fileSystem: memoryFileSystem)),
  ];

  for (var feedManagerTest in feedManagerTests) {
    group('${feedManagerTest.feedManager.id} feed manager', () {
      test('adds to feed', () async {
        // Verify that we start with no videos in the feed
        expect(feedManagerTest.feedManager.feed.videos.length, 0);

        // Add a video
        await feedManagerTest.feedManager.add(Examples.servedVideo1);

        // Verify that the new video was added
        expect(feedManagerTest.feedManager.feed.videos.length, 1);
        expect(
            feedManagerTest.feedManager.feed.videos[0], Examples.servedVideo1);

        // Add a couple more videos
        await feedManagerTest.feedManager
            .addAll([Examples.servedVideo2, Examples.servedVideo3]);

        // Verify that the videos were added
        expect(feedManagerTest.feedManager.feed.videos.length, 3);
        expect(feedManagerTest.feedManager.feed.videos.toList(), [
          Examples.servedVideo1,
          Examples.servedVideo2,
          Examples.servedVideo3
        ]);
      });
    });
  }
}
