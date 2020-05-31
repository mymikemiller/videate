import 'dart:io' as io;
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:vidlib/vidlib.dart';
import 'package:path/path.dart' as p;
import '../../uploader.dart';

// Saves the file to disk instead of uploading it
class SaveToDiskUploader extends Uploader {
  @override
  String get id => 'save_to_disk';

  final io.Directory directory;
  final FileSystem fileSystem;
  SaveToDiskUploader(this.directory,
      {this.fileSystem = const LocalFileSystem()});

  @override
  Future<ServedVideo> upload(VideoFile videoFile) async {
    final uri = getDestinationUri(p.basename(videoFile.file.path));

    copy(videoFile.file, uri.path);

    final servedVideo = ServedVideo((b) => b
      ..video = videoFile.video.toBuilder()
      ..uri = uri
      ..lengthInBytes = videoFile.file.lengthSync());

    return servedVideo;
  }

  @override
  Uri getDestinationUri(String filename) {
    return Uri(path: p.join(directory.path, filename));
  }

  // Copies the contents of 'file' into a new file at 'path' on this
  // SaveToDiskUploader's fileSystem. This function can be used to copy files
  // from a file system other than the LocalFileSystem, such as the File
  // library's MemoryFileSystem, where the file.copy() function fails.
  File copy(io.File file, String path) {
    final newFile = fileSystem.file(path);
    newFile.createSync(recursive: true);

    // TODO: Don't read the whole file all at once. See:
    // https://stackoverflow.com/questions/20815913/how-to-read-a-file-line-by-line-in-dart
    // https://github.com/google/file.dart/issues/134
    List bytes = file.readAsBytesSync();

    newFile.writeAsBytesSync(bytes);
    return newFile;
  }
}
