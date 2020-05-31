import 'dart:io';
import 'dart:convert' show json;
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import 'package:built_collection/built_collection.dart';
import 'mock_downloaders/mock_youtube_downloader.dart';
import '../bin/integrations/youtube/channel_source_collection.dart';
import '../bin/integrations/local/local_downloader.dart';
import '../bin/integrations/local/local_source_collection.dart';
import '../bin/downloader.dart';
import '../bin/source_collection.dart';

bool allVideosAreAfter(List<Video> videos, DateTime dateInclusive) {
  return videos
      .every((video) => video.sourceReleaseDate.compareTo(dateInclusive) >= 0);
}

class DownloaderTest {
  final Downloader downloader;
  final SourceCollection sourceCollection;

  // A date in the middle of the collection so we can test videosAfter
  final DateTime videosAfterDate;

  DownloaderTest(this.downloader, this.sourceCollection, this.videosAfterDate);
}

void main() {
  final ffprobeStub = (String executable, List<String> arguments) =>
      ProcessResult(
          0,
          0,
          arguments.last.contains('six_second_video')
              ? '0:00:06.038000'
              : '0:00:09.038000',
          '');

  final downloaderTests = [
    DownloaderTest(
        LocalDownloader(ffprobeRunner: ffprobeStub),
        LocalSourceCollection('test/resources/videos'),
        DateTime.parse('2019-12-28T18:04:27.000Z')),
    DownloaderTest(
        MockYoutubeDownloader(),
        YoutubeChannelSourceCollection('TEST_CHANNEL_ID'),
        DateTime.parse('2019-12-28T18:04:27.000Z'))
  ];

  for (var downloaderTest in downloaderTests) {
    group('${downloaderTest.downloader.id} downloader', () {
      test('gets all video upload metadata for a channel', () async {
        final result = await downloaderTest.downloader
            .allVideos(downloaderTest.sourceCollection)
            .toList();

        // Verify that the results are correctly returned in descending order by
        // date. The YouTube API often returns videos out of order (and so does
        // our test data)
        final sortedResults = List.from(result);
        sortedResults
            .sort((a, b) => b.sourceReleaseDate.compareTo(a.sourceReleaseDate));
        expect(result, sortedResults);

        final serializableResult = BuiltList<Video>(result);

        // Uncomment these lines to copy the results of the test for use in
        // modifying the expected result file.
        // final serializedResult = jsonSerializers.serialize(serializableResult);
        // final encodedResult = json.encode(serializedResult);

        final expectedResultFile = await File(
            'test/resources/${downloaderTest.downloader.id}/all_uploads_expected.json');
        final expectedResultJsonString =
            await expectedResultFile.readAsString();
        final decodedExpectedResult = json.decode(expectedResultJsonString);
        final expectedResult =
            jsonSerializers.deserialize(decodedExpectedResult);

        expect(serializableResult, expectedResult);
      });

      test('gets only videos uploaded after specified date', () async {
        // startDate was chosen as a date in the middle of the list of test
        // videos, so we can test that some are properly excluded
        final result = await downloaderTest.downloader
            .videosAfter(
                downloaderTest.videosAfterDate, downloaderTest.sourceCollection)
            .toList();

        // Verify that the results are correctly returned in descending order by
        // date. The YouTube API often returns videos out of order (and so does
        // our test data)
        final copy = List.from(result);
        copy.sort((a, b) => b.sourceReleaseDate.compareTo(a.sourceReleaseDate));
        expect(result, copy);

        // Verify that we didn't receive any videos outside the expected date range
        expect(allVideosAreAfter(result, downloaderTest.videosAfterDate), true);

        final serializableResult = BuiltList<Video>(result);

        // Uncomment these lines to copy the results of the test for use in
        // modifying the expected result file.
        // final serializedResult = jsonSerializers.serialize(serializableResult);
        // final encodedResult = json.encode(serializedResult);

        final expectedResultFile = await File(
            'test/resources/${downloaderTest.downloader.id}/videos_after_expected.json');
        final expectedResultJsonString =
            await expectedResultFile.readAsString();
        final decodedExpectedResult = json.decode(expectedResultJsonString);
        final expectedResult =
            jsonSerializers.deserialize(decodedExpectedResult);

        expect(serializableResult, expectedResult);
      });
    });
  }
}
