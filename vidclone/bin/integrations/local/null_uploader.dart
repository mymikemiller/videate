import 'package:file/file.dart';
import 'package:vidlib/vidlib.dart';
import '../../uploader.dart';

// Does nothing. Does not upload the file anywhere, and simply returns a
// ServedMedia pointing to the original file.
class NullUploader extends Uploader {
  @override
  String get id => 'null';

  final Directory baseDirectory;

  NullUploader(this.baseDirectory);

  @override
  void configure(ClonerTaskArgs uploaderArgs) {}

  @override
  Future<ServedMedia> uploadMedia(MediaFile mediaFile,
      [Function(double progress) callback]) async {
    final uri = getDestinationUri(mediaFile.media);

    final servedMedia = ServedMedia((b) => b
      ..media = mediaFile.media.toBuilder()
      ..uri = uri
      ..etag = _generateEtag(mediaFile)
      ..lengthInBytes = mediaFile.file.lengthSync());

    return servedMedia;
  }

  String _generateEtag(MediaFile mediaFile) {
    // Assume a file has not been changed if its size exactly matches. Using a
    // crypto checksum shoudn't be necessary.
    return mediaFile.file.lengthSync().toString();
  }

  @override
  Uri getDestinationUri(Media media, [extension = 'mp4']) {
    return media.source.uri;
  }

  @override
  Future<ServedMedia> getExistingServedMedia(Media media) async {
    final uri = getDestinationUri(media);
    final file = baseDirectory.fileSystem.file(Uri.decodeFull(uri.path));
    if (!file.existsSync()) {
      return null;
    }

    return ServedMedia((b) => b
      ..uri = uri
      ..media = media.toBuilder()
      ..etag = _generateEtag(MediaFile(media, file))
      ..lengthInBytes = file.lengthSync());
  }
}
