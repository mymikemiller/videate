import 'package:file/local.dart';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import '../bin/integrations/media_converters/ffmpeg_media_converter.dart';
import '../bin/media_converter.dart';
import 'package:built_collection/built_collection.dart';
import 'test_utilities.dart';

class MediaConverterTest {
  final MediaConverter mediaConverter;
  MediaConverterTest({this.mediaConverter});
}

void main() async {
  final testMediaFile =
      LocalFileSystem().file('test/resources/media/video_1.mp4');
  final mediaFile = MediaFile(Examples.media1, testMediaFile);

  List<MediaConverterTest> generateMediaConverterTests() => [
        MediaConverterTest(
            mediaConverter: FfmpegMediaConverter()
              ..conversionArgs = ClonerTaskArgs((a) => a
                ..id = 'ffmpeg'
                ..args = [
                  'ffmpeg',
                  'vcodec',
                  'libx264',
                  'height',
                  '240',
                  'crf',
                  '30'
                ].toBuiltList().toBuilder()))
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
        await mediaConverterTest.mediaConverter.convert(mediaFile);
      });
    });

    mediaConverterTest.mediaConverter.close();
  }
}
