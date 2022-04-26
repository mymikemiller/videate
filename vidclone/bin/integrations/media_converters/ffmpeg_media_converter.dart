import 'package:vidlib/vidlib.dart';
import '../../media_converter.dart';

class FfmpegMediaConverter extends MediaConverter {
  static final String _id = 'ffmpeg';

  @override
  String get id => _id;

  @override
  Future<MediaFile> convertMedia(MediaFile mediaFile,
      [Function(double progress) callback]) async {
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
