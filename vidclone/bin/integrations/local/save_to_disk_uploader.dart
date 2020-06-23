import 'dart:io' as io;
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
      ..etag = 'a1b2c3'
      ..lengthInBytes = videoFile.file.lengthSync());

    return servedVideo;
  }

  @override
  Uri getDestinationUri(Video video, [extension = 'mp4']) {
    // Put videos from the same source into folders named with the uploader's
    // id to ensure that we don't have collisions between videos from different
    // sources. Use the Video's source id in the file name to ensure we don't
    // have collisions between videos from the same source that happen to have
    // the same title.
    return Uri.parse(
        p.join(directory.path, '${video.source.id}_${video.title}.$extension'));
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
