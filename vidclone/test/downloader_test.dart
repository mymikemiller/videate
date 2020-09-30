import 'dart:io';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import 'package:crypto/crypto.dart';
import 'package:built_collection/built_collection.dart';
import '../bin/integrations/local/local_downloader.dart';
import '../bin/integrations/youtube/youtube_downloader.dart';
import '../bin/downloader.dart';
import 'mock_downloaders/mock_youtube_downloader.dart';
import 'package:collection/collection.dart';

bool allMediaAreInOrder(List<Media> media) {
  final sortedMedia = List.from(media).cast<Media>();

  sortedMedia.sort((Media a, Media b) {
    var cmp = b.source.releaseDate.compareTo(a.source.releaseDate);
    if (cmp == 0) {
      // When dates match, secondarily sort by uri path
      return b.source.uri.path.compareTo(a.source.uri.path);
    }
    return cmp;
  });

  return ListEquality().equals(media.toList(), sortedMedia.toList());
}

bool allMediaAreAfter(List<Media> media, DateTime dateInclusive) {
  return media.every((m) => m.source.releaseDate.compareTo(dateInclusive) >= 0);
}

class DownloaderTest {
  final Downloader downloader;

  // A date in the middle of the collection so we can test mediaAfter
  final DateTime mediaAfterDate;

  // Media that this downloader is capable of downloading
  final Media testMedia;

  // The platform's unique id for [testMedia]
  final String testMediaUniqueId;

  DownloaderTest(
      {this.downloader,
      this.mediaAfterDate,
      this.testMedia,
      this.testMediaUniqueId});
}

void main() async {
  final ffprobeStub = (String executable, List<String> arguments) =>
      ProcessResult(
          0,
          0,
          arguments.last.contains('d') ? '0:00:06.038000' : '0:00:09.038000',
          '');
  final testMediaFile = File('test/resources/media/video_1.mp4');
  final testMediaFileHash = md5.convert(testMediaFile.readAsBytesSync());

  List<DownloaderTest> generateDownloaderTests() => [
        DownloaderTest(
            downloader: LocalDownloader(ffprobeRunner: ffprobeStub)
              ..configure(ClonerTaskArgs((a) => a
                ..id = 'local'
                ..args = ['path', 'test/resources/media']
                    .toBuiltList()
                    .toBuilder())),
            // The sourceReleaseDate of all LocalDownloader Media is epoch, so
            // the mediaAfter test for LocalDownloader is not very useful but
            // is here for completeness
            mediaAfterDate: DateTime.parse('1970-01-01T00:00:00.000Z'),
            testMedia: Examples.media1.rebuild(
              (v) => v
                ..source = Source(
                  (s) => s
                    ..platform = LocalDownloader.getPlatform().toBuilder()
                    ..releaseDate =
                        DateTime.fromMillisecondsSinceEpoch(0).toUtc()
                    ..id = 'abc123'
                    ..uri = testMediaFile.uri,
                ).toBuilder(),
            )),
        DownloaderTest(
            downloader: MockYoutubeDownloader(testMediaFile)
              ..configure(ClonerTaskArgs((a) => a
                ..id = 'youtube'
                ..args = ['channelId', 'UC9CuvdOVfMPvKCiwdGKL3cQ']
                    .toBuiltList()
                    .toBuilder())),
            mediaAfterDate: DateTime.parse('2020-01-02 09:37:16.000'),
            testMedia: Examples.media1.rebuild(
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
      test('gets all media upload metadata for a source collection', () async {
        final result = await downloaderTest.downloader
            .reverseChronologicalMedia()
            .toList();

        // Verify that the results are correctly returned in descending order
        // by date. The YouTube API, for example, often returns videos out of
        // order (and so does our test data).
        expect(allMediaAreInOrder(result), true);

        final serializableResult = BuiltList<Media>(result);

        final expectedResultFile = await File(
            'test/resources/${downloaderTest.downloader.platform.id}/all_media_in_order_expected.json');

        await TestUtilities.testListSerialization(
            serializableResult, expectedResultFile);
      });

      test('gets most recent media', () async {
        final mostRecentExpected = await downloaderTest.downloader
            .allMedia()
            .reduce((previous, element) =>
                previous.source.releaseDate.isAfter(element.source.releaseDate)
                    ? previous
                    : element);

        final mostRecent = await downloaderTest.downloader.mostRecentMedia();

        expect(mostRecent, mostRecentExpected);
      });

      test('gets only media uploaded after specified date', () async {
        final result = await downloaderTest.downloader
            .reverseChronologicalMedia(downloaderTest.mediaAfterDate)
            .toList();

        // Verify that we didn't receive any media outside the expected date
        // range
        expect(allMediaAreAfter(result, downloaderTest.mediaAfterDate), true);

        final serializableResult = BuiltList<Media>(result);

        final expectedResultFile = await File(
            'test/resources/${downloaderTest.downloader.platform.id}/media_after_expected.json');

        await TestUtilities.testJsonSerialization(
            serializableResult, expectedResultFile);
      });

      test('downloads Media', () async {
        final mediaFile =
            await downloaderTest.downloader.download(downloaderTest.testMedia);
        expect(mediaFile.media, downloaderTest.testMedia);

        // Use the hash to verify that we got the expected file
        final mediaHash = md5.convert(await mediaFile.file.readAsBytes());
        expect(mediaHash, testMediaFileHash);
      });
    });

    downloaderTest.downloader.close();
  }
}
