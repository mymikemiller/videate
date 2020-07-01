import 'dart:io';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import 'package:crypto/crypto.dart';
import 'package:built_collection/built_collection.dart';
import '../bin/integrations/youtube/channel_source_collection.dart';
import '../bin/integrations/local/local_downloader.dart';
import '../bin/integrations/local/local_source_collection.dart';
import '../bin/integrations/youtube/youtube_downloader.dart';
import '../bin/downloader.dart';
import '../bin/source_collection.dart';
import 'mock_downloaders/mock_youtube_downloader.dart';
import 'package:collection/collection.dart';

bool allVideosAreInOrder(List<Video> videos) {
  final sortedVideos = List.from(videos).cast<Video>();

  sortedVideos.sort((Video a, Video b) {
    var cmp = b.source.releaseDate.compareTo(a.source.releaseDate);
    if (cmp == 0) {
      // When dates match, secondarily sort by uri path
      return b.source.uri.path.compareTo(a.source.uri.path);
    }
    return cmp;
  });

  return ListEquality().equals(videos.toList(), sortedVideos.toList());
}

bool allVideosAreAfter(List<Video> videos, DateTime dateInclusive) {
  return videos
      .every((video) => video.source.releaseDate.compareTo(dateInclusive) >= 0);
}

class DownloaderTest {
  final Downloader downloader;
  final SourceCollection sourceCollection;

  // A date in the middle of the collection so we can test videosAfter
  final DateTime videosAfterDate;

  // A video that this downloader is capable of downloading
  final Video testVideo;

  // The platform's unique id for [testVideo]
  final String testVideoUniqueId;

  DownloaderTest(
      {this.downloader,
      this.sourceCollection,
      this.videosAfterDate,
      this.testVideo,
      this.testVideoUniqueId});
}

void main() async {
  final ffprobeStub = (String executable, List<String> arguments) =>
      ProcessResult(
          0,
          0,
          arguments.last.contains('d') ? '0:00:06.038000' : '0:00:09.038000',
          '');
  final testVideoFile = File('test/resources/videos/video_1.mp4');
  final testVideoFileHash = md5.convert(await testVideoFile.readAsBytes());

  List<DownloaderTest> generateDownloaderTests() => [
        DownloaderTest(
            downloader: LocalDownloader(ffprobeRunner: ffprobeStub),
            sourceCollection: LocalSourceCollection('test/resources/videos'),
            // The sourceReleaseDate of all LocalDownloader Videos is epoch, so the
            // videosAfter test for LocalDownloader is not very useful
            videosAfterDate: DateTime.parse('1970-01-01T00:00:00.000Z'),
            testVideo: Examples.video1.rebuild(
              (v) => v
                ..source = Source(
                  (s) => s
                    ..platform = LocalDownloader.getPlatform().toBuilder()
                    ..releaseDate =
                        DateTime.fromMillisecondsSinceEpoch(0).toUtc()
                    ..id = 'abc123'
                    ..uri = testVideoFile.uri,
                ).toBuilder(),
            )),
        DownloaderTest(
            downloader: MockYoutubeDownloader(testVideoFile),
            sourceCollection:
                YoutubeChannelSourceCollection('UC9CuvdOVfMPvKCiwdGKL3cQ'),
            videosAfterDate: DateTime.parse('2020-01-02 09:37:16.000'),
            testVideo: Examples.video1.rebuild(
              (v) => v
                ..source = Source(
                  (s) => s
                    ..platform = YoutubeDownloader.getPlatform().toBuilder()
                    ..releaseDate =
                        DateTime.fromMillisecondsSinceEpoch(0).toUtc()
                    ..id =
                        'abc12345678' // Valid youtube videoIds have 11 characters
                    ..uri = Uri.parse(
                        'https://www.youtube.com/watch?v=abc12345678'),
                ).toBuilder(),
            ))
      ];

  var downloaderTests = generateDownloaderTests();
  setUp(() async {
    downloaderTests = generateDownloaderTests();
  });

  for (var downloaderTest in downloaderTests) {
    group('${downloaderTest.downloader.platform.id} downloader', () {
      test('gets all video upload metadata for a source collection', () async {
        final result = await downloaderTest.downloader
            .allVideosInOrder(downloaderTest.sourceCollection)
            .toList();

        // Verify that the results are correctly returned in descending order
        // by date. The YouTube API, for example, often returns videos out of
        // order (and so does our test data).
        expect(allVideosAreInOrder(result), true);

        final serializableResult = BuiltList<Video>(result);

        final expectedResultFile = await File(
            'test/resources/${downloaderTest.downloader.platform.id}/all_videos_in_order_expected.json');

        await TestUtilities.testListSerialization(
            serializableResult, expectedResultFile);
      });

      test('gets most recent video', () async {
        final mostRecentExpected = await downloaderTest.downloader
            .allVideos(downloaderTest.sourceCollection)
            .reduce((previous, element) =>
                previous.source.releaseDate.isAfter(element.source.releaseDate)
                    ? previous
                    : element);

        // Reset the downloader so we can use the stream. This avoids "Stream
        // has already been listened to" error on the next line. There's
        // probably a better way to handle this...
        // https://github.com/Hexer10/youtube_explode_dart/issues/48
        downloaderTests = generateDownloaderTests();

        final mostRecent = await downloaderTest.downloader
            .mostRecentVideo(downloaderTest.sourceCollection);

        expect(mostRecent, mostRecentExpected);
      });

      test('gets only videos uploaded after specified date', () async {
        final result = await downloaderTest.downloader
            .videosAfter(
                downloaderTest.videosAfterDate, downloaderTest.sourceCollection)
            .toList();

        // Verify that we didn't receive any videos outside the expected date range
        expect(allVideosAreAfter(result, downloaderTest.videosAfterDate), true);

        final serializableResult = BuiltList<Video>(result);

        final expectedResultFile = await File(
            'test/resources/${downloaderTest.downloader.platform.id}/videos_after_expected.json');

        await TestUtilities.testJsonSerialization(
            serializableResult, expectedResultFile);
      });

      test('downloads a Video', () async {
        final videoFile =
            await downloaderTest.downloader.download(downloaderTest.testVideo);
        expect(videoFile.video, downloaderTest.testVideo);

        // Use the hash to verify that we got the expected file
        final videoHash = md5.convert(await videoFile.file.readAsBytes());
        expect(videoHash, testVideoFileHash);
      });
    });
  }
}
