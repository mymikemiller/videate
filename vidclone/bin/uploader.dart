import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:vidlib/vidlib.dart';

abstract class Uploader {
  // An id unique to this uploader, e.g. "internet_archive".
  String get id;

  Future<ServedVideo> upload(VideoFile file);

  Uri getDestinationUri(String filename);

  // Returns true if the file with the given filename already exists at the
  // destination
  Future<bool> existsAtDestination(String filename,
      {FileSystem fileSystem = const LocalFileSystem()}) {
    final destinationUri = getDestinationUri(filename);

    // This will only work for file-based uploads. When we upload to a CDN,
    // we'll need to update this to switch based on the scheme.
    return fileSystem.file(destinationUri.path).exists();
  }
}
