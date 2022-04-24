import 'package:file/file.dart';
import 'package:built_collection/built_collection.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import '../bin/integrations/local/json_file_feed_manager.dart';
import '../bin/integrations/internet_computer/internet_computer_feed_manager.dart';
import 'package:path/path.dart' as p;
import '../bin/feed_manager.dart';
import 'package:meta/meta.dart';
import 'mock_feed_managers/mock_rsync_feed_manager.dart';
import 'mock_feed_managers/mock_internet_computer_feed_manager.dart';
import 'test_utilities.dart';

final memoryFileSystem = MemoryFileSystem();

class FeedManagerTest {
  FeedManager _feedManager;
  FeedManager get feedManager => _feedManager;
  final FeedManager Function() createFeedManager;
  final Function(FeedManager feedManager, Feed feed) mockValidSourceFeed;
  final Function(FeedManager feedManager) mockInvalidSourceFeed;

  FeedManagerTest(
      {@required this.createFeedManager,
      @required this.mockValidSourceFeed,
      @required this.mockInvalidSourceFeed}) {
    resetFeedManager();
  }

  void resetFeedManager() {
    _feedManager = createFeedManager();
  }
}

final successMockClient = (Feed feed) => MockClient((request) async {
      final json = feed.toJson().toString();
      return Response(json, 200, headers: {
        'etag': 'a1b2c3',
        'content-length': json.length.toString()
      });
    });

final successDfxProcess = (Feed feed) => MockClient((request) async {
      final json = feed.toJson().toString();
      return Response(json, 200, headers: {
        'etag': 'a1b2c3',
        'content-length': json.length.toString()
      });
    });

void main() async {
  final feedName = 'feed.json';
  final tempDirectory = createTempDirectory(memoryFileSystem);
  final feedPath = p.join(tempDirectory.path, feedName);

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
            createFeedManager: () => MockInternetComputerFeedManager()
              ..configure(ClonerTaskArgs((a) => a
                ..id = 'internet_computer'
                ..args = [
                  'name',
                  'test',
                  'key',
                  'test',
                  'network',
                  'local',
                  'dfxWorkingDirectory',
                  '/directory/not/needed/for/tests'
                ].toBuiltList().toBuilder())),
            mockValidSourceFeed: (feedManager, feed) =>
                (feedManager as MockInternetComputerFeedManager)
                        .mostRecentlyWrittenCandid =
                    InternetComputerFeedManager.toCandidString(feed),
            mockInvalidSourceFeed: (feedManager) =>
                (feedManager as MockInternetComputerFeedManager)
                    .mostRecentlyWrittenCandid = null),
        FeedManagerTest(
            createFeedManager: () => JsonFileFeedManager()
              ..fileSystem = memoryFileSystem
              ..configure(ClonerTaskArgs((a) => a
                ..id = 'json_file'
                ..args = ['path', feedPath].toBuiltList().toBuilder())),
            mockValidSourceFeed: (feedManager, feed) =>
                createSourceFeed(memoryFileSystem, feed),
            mockInvalidSourceFeed: (feedManager) =>
                deleteSourceFeed(memoryFileSystem)),
        FeedManagerTest(
            createFeedManager: () => MockRsyncFeedManager()
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
      setUp(() async {
        // Start each test with the test's default feed manager
        feedManagerTest.resetFeedManager();
      });

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

      test('handles quoted etag', () async {
        // Add quotes around the etag
        final quotedEtag = '"${Examples.feed1.mediaList[0].etag}"';
        feedManagerTest.feedManager.feed = Examples.feed1.rebuild((f) => f
          ..mediaList[0] = f.mediaList[0].rebuild((m) => m..etag = quotedEtag));

        // Writing and repopulating should preserve the quotes
        await feedManagerTest.feedManager.write();
        final populatedSuccessfully =
            await feedManagerTest.feedManager.populate();
        expect(populatedSuccessfully, true);
        expect(feedManagerTest.feedManager.feed.mediaList[0].etag, quotedEtag);
      });
    });

    feedManagerTest.feedManager.close();
  }
}
