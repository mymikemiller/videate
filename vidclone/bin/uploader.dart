import 'package:file/file.dart';
import 'package:http/http.dart' as http;
import 'package:vidlib/vidlib.dart';

abstract class Uploader {
  /// An id unique to this uploader, e.g. "internet_archive".
  String get id;

  /// fileSystem must be specified for file-based uploaders (uploaders whose
  /// destination is a file on a file system, not a file on the web)
  FileSystem get fileSystem => null;

  /// httpGet, used to determine whether a file already exists at the upload
  /// destination, defaults to the [get] function in the [http] library, but
  /// can be overridden for testing purposes
  Future<http.Response> httpGet(url, {Map<String, String> headers}) {
    return http.get(url, headers: headers);
  }

  Uploader();

  /// Uploads the file so it is available at the destination returned by
  /// [getDestinationUri].
  Future<ServedVideo> upload(VideoFile file);

  /// Get a Uri that is guaranteed to be unique to this video among all videos,
  /// even across different sources.
  Uri getDestinationUri(Video video);

  /// Returns true if the video already exists at the destination
  Future<bool> existsAtDestination(Video video) async {
    final uri = getDestinationUri(video);
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      // Assume the video has been uploaded already if we get a 200 response at
      // the destination
      final response = await httpGet(uri);
      if (response.statusCode != 200) {
        print(
            'Video does not exist at destination ${uri}. If the file is still '
            'processing, it may be a moment before the file is available at '
            'the destination.');
      }
      return response.statusCode == 200;
    } else {
      if (fileSystem == null) {
        throw 'File-based uploaders must specify a fileSystem';
      }

      // This is a file-based uploader. Check for a file on the given
      // fileSystem
      return fileSystem.file(uri).exists();
    }
  }
}
