import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:built_collection/built_collection.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import '../bin/integrations/local/json_file_feed_manager.dart';
import 'package:path/path.dart' as p;
import '../bin/feed_manager.dart';
import 'package:meta/meta.dart';
import 'mock_feed_manager.dart/mock_rsync_feed_manager.dart';
import 'test_utilities.dart';

final memoryFileSystem = MemoryFileSystem();

class FeedManagerTest {
  final FeedManager feedManager;
  final Function(FeedManager feedManager, Feed feed) mockValidSourceFeed;
  final Function(FeedManager feedManager) mockInvalidSourceFeed;

  FeedManagerTest(
      {@required this.feedManager,
      @required this.mockValidSourceFeed,
      @required this.mockInvalidSourceFeed});
}

final successMockClient = (Feed feed) => MockClient((request) async {
      final json = feed.toJson().toString();
      return Response(json, 200, headers: {
        'etag': 'a1b2c3',
        'content-length': json.length.toString()
      });
    });

void main() async {
  final feedName = 'feed.json';
  final feedPath = p.join(memoryFileSystem.systemTempDirectory.path, feedName);
  final feedDirectory = memoryFileSystem.directory(feedPath);

  final createSourceFeed = (FileSystem fileSystem, Feed feed) {
    final file = fileSystem.file(feedPath);
    file.createSync(recursive: true);
    file.writeAsStringSync(feed.toJson());
  };
  final deleteSourceFeed = (FileSystem fileSystem) {
    final file = fileSystem.file(feedPath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  };

  List<FeedManagerTest> generateFeedManagerTests() => [
        FeedManagerTest(
            feedManager: JsonFileFeedManager()
              ..fileSystem = memoryFileSystem
              ..configure(ClonerTaskArgs((a) => a
                ..id = 'json_file'
                ..args = ['path', feedPath].toBuiltList().toBuilder())),
            mockValidSourceFeed: (feedManager, feed) =>
                createSourceFeed(memoryFileSystem, feed),
            mockInvalidSourceFeed: (feedManager) =>
                deleteSourceFeed(memoryFileSystem)),
        FeedManagerTest(
            feedManager: MockRsyncFeedManager()
              ..configure(ClonerTaskArgs((a) => a
                ..id = 'rsync'
                ..args = ['path', feedPath].toBuiltList().toBuilder())),
            mockValidSourceFeed: (feedManager, feed) =>
                feedManager.client = successMockClient(feed),
            mockInvalidSourceFeed: (feedManager) =>
                feedManager.client = failureMockClient),
      ];

  var feedManagerTests = generateFeedManagerTests();
  setUp(() async {
    feedManagerTests = generateFeedManagerTests();
  });

  tearDown(() async {
    for (var feedManagerTest in feedManagerTests) {
      feedManagerTest.feedManager.close();
    }
  });

  for (var feedManagerTest in feedManagerTests) {
    group('${feedManagerTest.feedManager.id} feed manager', () {
      test('throws error when accessing null feed', () async {
        feedManagerTest.feedManager.feed = null;
        // Trying to access the feed should throw a StateError with a helpful
        // message
        expect(() => feedManagerTest.feedManager.feed, throwsStateError);
      });

      test('recognizes invalid source', () async {
        feedManagerTest.mockInvalidSourceFeed(feedManagerTest.feedManager);
        var populatedSuccessfully =
            await feedManagerTest.feedManager.populate();
        expect(populatedSuccessfully, false);
        expect(() => feedManagerTest.feedManager.feed, throwsStateError);
      });

      test('populates from source', () async {
        feedManagerTest.mockValidSourceFeed(
            feedManagerTest.feedManager, Examples.feed1);
        final populatedSuccessfully =
            await feedManagerTest.feedManager.populate();
        expect(populatedSuccessfully, true);
        expect(feedManagerTest.feedManager.feed, Examples.feed1);
      });

      test('adds media', () async {
        feedManagerTest.feedManager.feed = Examples.emptyFeed;
        expect(feedManagerTest.feedManager.feed.mediaList.length, 0);
        await feedManagerTest.feedManager.add(Examples.servedMedia1);
        expect(feedManagerTest.feedManager.feed.mediaList.length, 1);
        await feedManagerTest.feedManager
            .addAll([Examples.servedMedia2, Examples.servedMedia3]);
        expect(feedManagerTest.feedManager.feed.mediaList.length, 3);
        expect(feedManagerTest.feedManager.feed.mediaList.toList(), [
          Examples.servedMedia1,
          Examples.servedMedia2,
          Examples.servedMedia3
        ]);
      });

      test('writes feed', () async {
        feedManagerTest.feedManager.feed = Examples.feed1;
        await feedManagerTest.feedManager.write();

        feedManagerTest.feedManager.feed = Examples.emptyFeed;
        expect(feedManagerTest.feedManager.feed, Examples.emptyFeed);

        // Populate should bring back the feed we wrote
        await feedManagerTest.feedManager.populate();
        expect(feedManagerTest.feedManager.feed, Examples.feed1);
      });
    });

    feedManagerTest.feedManager.close();
  }
}
