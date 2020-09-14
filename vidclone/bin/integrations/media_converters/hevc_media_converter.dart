import 'package:vidlib/src/models/media_file.dart';
import 'package:vidlib/vidlib.dart';
import 'package:meta/meta.dart';
import '../../media_converter.dart';

class HevcMediaConverter extends MediaConverter {
  static final String _id = 'HEVC';

  @override
  String get id => _id;

  // Expected conversionArgs format: ['height', 'XXX', 'crf', 'YY']
  static MediaConversionArgs createArgs(
          {@required int height, @required int crf}) =>
      MediaConverter.createArgs(_id, ['height', '$height', 'crf', '$crf']);

  @override
  Future<MediaFile> convert(
      MediaFile mediaFile, MediaConversionArgs conversionArgs,
      {Function(double progress) callback}) async {
    final height = int.parse(conversionArgs.get('height'));
    final crf = int.parse(conversionArgs.get('crf'));

    var converter = VideoConverter(processStarter: processStarter);
    final convertedFile = await converter.convert(
      mediaFile.file,
      height: height,
      crf: crf,
      callback: callback,
    );
    final convertedMediaFile = MediaFile(mediaFile.media, convertedFile);
    return convertedMediaFile;
  }
}
