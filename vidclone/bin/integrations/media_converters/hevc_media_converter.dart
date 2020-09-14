import 'package:vidlib/src/models/media_file.dart';
import 'package:vidlib/vidlib.dart';

import '../../media_converter.dart';

class HevcMediaConverter extends MediaConverter {
  // Expected conversionArgs format: ['height', 'XXX', 'crf', 'YY']
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
