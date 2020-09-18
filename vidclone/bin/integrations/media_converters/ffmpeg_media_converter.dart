import 'package:vidlib/src/models/media_file.dart';
import 'package:vidlib/vidlib.dart';
import 'package:meta/meta.dart';
import '../../media_converter.dart';

class FfmpegMediaConverter extends MediaConverter {
  static final String _id = 'ffmpeg';

  @override
  String get id => _id;

  // Expected conversionArgs format: ['vcodec', 'X', 'height', 'Y', 'crf', 'Z']
  static MediaConversionArgs createArgs(
          {@required String vcodec, @required int height, @required int crf}) =>
      MediaConverter.createArgs(
          _id, ['vcodec', '$vcodec', 'height', '$height', 'crf', '$crf']);

  @override
  Future<MediaFile> convert(
      MediaFile mediaFile, MediaConversionArgs conversionArgs,
      {Function(double progress) callback}) async {
    final vcodec = conversionArgs.get('vcodec');
    final height = int.parse(conversionArgs.get('height'));
    final crf = int.parse(conversionArgs.get('crf'));

    var converter = FfmpegVideoConverter(processStarter: processStarter);
    final convertedFile = await converter.convert(
      mediaFile.file,
      vcodec: vcodec,
      height: height,
      crf: crf,
      callback: callback,
    );
    final convertedMediaFile = MediaFile(mediaFile.media, convertedFile);
    return convertedMediaFile;
  }
}