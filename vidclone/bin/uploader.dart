import 'package:file/file.dart';
import 'package:http/http.dart';
import 'package:vidlib/vidlib.dart';

abstract class Uploader {
  /// An id unique to this uploader, e.g. "internet_archive".
  String get id;

  /// fileSystem must be specified for file-based uploaders (uploaders whose
  /// destination is a file on a file system, not a file on the web)
  FileSystem get fileSystem => null;

  Client client = Client();

  Uploader();

  /// Uploads the file so it is available at the destination returned by
  /// [getDestinationUri].
  Future<ServedVideo> upload(VideoFile file);

  /// Get a Uri that is guaranteed to be unique to this video among all videos,
  /// even across different sources.
  Uri getDestinationUri(Video video);

  // Returns the [ServedVideo] if it already exists at the destination,
  // otherwise returns null.
  Future<ServedVideo> getExistingServedVideo(Video video);

  // Perform any cleanup. This uploader should no longer be used after this is
  // called.
  void close();
}
