import 'package:vidlib/src/models/media_file.dart';
import 'package:vidlib/vidlib.dart';
import '../../media_converter.dart';

/// A no-op converter
class NullMediaConverter extends MediaConverter {
  static final String _id = 'null';

  @override
  String get id => _id;

  @override
  Future<MediaFile> convertMedia(MediaFile mediaFile,
      [Function(double progress) callback]) async {
    return mediaFile;
  }
}
