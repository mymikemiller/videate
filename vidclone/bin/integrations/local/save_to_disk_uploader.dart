import 'package:file/file.dart';
import 'package:vidlib/vidlib.dart';
import 'package:path/path.dart' as p;
import '../../uploader.dart';

// Saves the file to disk instead of uploading it
class SaveToDiskUploader extends Uploader {
  @override
  String get id => 'save_to_disk';

  final Directory baseDirectory;
  String sourcePlatformId;
  String feedName;

  SaveToDiskUploader(this.baseDirectory);

  @override
  void configure(ClonerTaskArgs uploaderArgs) {
    feedName = uploaderArgs.get('feedName');
    sourcePlatformId = uploaderArgs.get('platformId');
  }

  @override
  Future<ServedMedia> uploadMedia(MediaFile mediaFile,
      [Function(double progress) callback]) async {
    final uri = getDestinationUri(mediaFile.media);

    await copyToFileSystem(mediaFile.file, baseDirectory.fileSystem, uri);

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
    // The media's source id is guaranteed to be unique among all media on that
    // source, so we use that as the filename. We won't have collisions across
    // sources because we also put each media into a folder named after its
    // source platform.
    return Uri.file(p.join(
        baseDirectory.path, sourcePlatformId, '${media.source.id}.$extension'));
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
