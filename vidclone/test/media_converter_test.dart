import 'package:file/local.dart';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import '../bin/integrations/media_converters/hevc_media_converter.dart';
import '../bin/media_converter.dart';

import 'test_utilities.dart';

class MediaConverterTest {
  final MediaConverter mediaConverter;
  final MediaConversionArgs mediaConversionArgs;

  MediaConverterTest({this.mediaConverter, this.mediaConversionArgs});
}

void main() async {
  final testMediaFile =
      LocalFileSystem().file('test/resources/media/video_1.mp4');
  final mediaFile = MediaFile(Examples.media1, testMediaFile);

  List<MediaConverterTest> generateMediaConverterTests() => [
        MediaConverterTest(
            mediaConverter: HevcMediaConverter(),
            mediaConversionArgs:
                HevcMediaConverter.createArgs(height: 240, crf: 30))
      ];

  var mediaConverterTests = generateMediaConverterTests();
  setUp(() async {
    mediaConverterTests = generateMediaConverterTests();
  });

  for (var mediaConverterTest in mediaConverterTests) {
    group('${mediaConverterTest.mediaConverter.id} media converter', () {
      test('converts media', () async {
        mediaConverterTest.mediaConverter.processStarter = noopProcessStart;
        // For now, we just want to make sure we don't get any errors when
        // `convert` is called
        await mediaConverterTest.mediaConverter
            .convert(mediaFile, mediaConverterTest.mediaConversionArgs);
      });
    });

    mediaConverterTest.mediaConverter.close();
  }
}
