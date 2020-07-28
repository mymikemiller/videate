import 'dart:io' as io;
import 'dart:io';
import 'package:file/file.dart' as file;
import 'package:vidlib/vidlib.dart';
import 'package:path/path.dart' as p;
import '../../uploader.dart';

// Saves the file to disk instead of uploading it
class SaveToDiskUploader extends Uploader {
  @override
  String get id => 'save_to_disk';

  final io.Directory directory;

  file.FileSystem _fileSystem;
  @override
  file.FileSystem get fileSystem => _fileSystem;

  SaveToDiskUploader(this.directory) {
    final entity = directory as file.FileSystemEntity;
    _fileSystem = entity.fileSystem;
  }

  @override
  Future<ServedVideo> upload(VideoFile videoFile) async {
    final uri = getDestinationUri(videoFile.video);

    copyToFileSystem(videoFile.file, uri);

    final servedVideo = ServedVideo((b) => b
      ..video = videoFile.video.toBuilder()
      ..uri = uri
      ..etag = _generateEtag(videoFile)
      ..lengthInBytes = videoFile.file.lengthSync());

    return servedVideo;
  }

  String _generateEtag(VideoFile videoFile) {
    // Assume a file has not been changed if its size exactly matches. Using a
    // crypto checksum shoudn't be necessary.
    return videoFile.file.lengthSync().toString();
  }

  @override
  Uri getDestinationUri(Video video, [extension = 'mp4']) {
    // The video's source id is guaranteed to be unique among all videos on that
    // source, so we use that as the filename. We won't have collisions across
    // sources because we also put each video into a folder named after its
    // source platform.
    return Uri.file(p.join(directory.path, '${video.source.id}.$extension'));
  }

  @override
  Future<ServedVideo> getExistingServedVideo(Video video) async {
    final uri = getDestinationUri(video);
    final file = fileSystem.file(Uri.decodeFull(uri.path));
    if (!file.existsSync()) {
      return null;
    }

    return ServedVideo((b) => b
      ..uri = uri
      ..video = video.toBuilder()
      ..etag = _generateEtag(VideoFile(video, file))
      ..lengthInBytes = file.lengthSync());
  }

  // Copies the contents of 'file' into a new file at 'path' on this
  // SaveToDiskUploader's fileSystem. This function can be used to copy files
  // from a file system other than the LocalFileSystem, such as the File
  // library's MemoryFileSystem, where the file.copy() function fails.
  file.File copyToFileSystem(io.File file, Uri uri) {
    final newFile = fileSystem.file(uri);
    newFile.createSync(recursive: true);

    // TODO: Don't read the whole file all at once. See:
    // https://stackoverflow.com/questions/20815913/how-to-read-a-file-line-by-line-in-dart
    // https://github.com/google/file.dart/issues/134
    List bytes = file.readAsBytesSync();

    newFile.writeAsBytesSync(bytes);
    return newFile;
  }

  @override
  void close() {
    // do nothing
  }
}
