import 'package:vidlib/vidlib.dart';
import 'cloner_task.dart';
import 'package:meta/meta.dart';

abstract class Uploader extends ClonerTask {
  /// An id unique to this uploader, e.g. "internet_archive".
  String get id;

  Uploader();

  /// Uploads the file so it is available at the destination returned by
  /// [getDestinationUri].
  @nonVirtual
  Future<ServedMedia> upload(MediaFile mediaFile,
      {Function(double progress) callback}) async {
    callback?.call(0);
    final servedMedia = await uploadMedia(mediaFile, callback);
    callback?.call(1);
    return servedMedia;
  }

  // Actual upload logic. To be implemented by subclasses.
  @protected
  Future<ServedMedia> uploadMedia(MediaFile file,
      [Function(double progress) callback]);

  /// Get a Uri that is guaranteed to be unique to this media among all media,
  /// even across different sources.
  Uri getDestinationUri(Media media);

  // Returns the [ServedMedia] if it already exists at the destination,
  // otherwise returns null.
  Future<ServedMedia> getExistingServedMedia(Media media) async {
    final uri = getDestinationUri(media);
    var response = await client.head(uri);
    if ([404, 403].contains(response.statusCode)) {
      // Media not found
      return null;
    }
    if (response.statusCode != 200) {
      throw 'received unexpected status code: ${response.statusCode}';
    }

    final etag = response.headers['etag'];
    final length = int.parse(response.headers['content-length']);

    return ServedMedia((b) => b
      ..uri = getDestinationUri(media)
      ..media = media.toBuilder()
      ..etag = etag
      ..lengthInBytes = length);
  }
}
