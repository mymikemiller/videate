import 'package:http/http.dart';
import 'package:vidlib/vidlib.dart' hide Platform;
import '../../uploader.dart';
import 'rsync.dart';

// Base class for uploaders that use the rsync command to upload.
abstract class RsyncUploader extends Uploader with Rsync {
  // Use the Uploader's client for rsync requests
  @override
  Client get rsyncClient => client;

  // Use the Uploader's processRunner to run the rsync process
  @override
  dynamic get rsyncProcessRunner => processRunner;

  RsyncUploader();

  String getKey(Media media, [String extension = 'mp4']) {
    return 'media/${media.source.platform.id}/${media.source.id}.$extension';
  }

  @override
  Future<ServedMedia> upload(MediaFile mediaFile) async {
    final key = getKey(mediaFile.media);
    await push(mediaFile.file, key);

    return ServedMedia((b) => b
      ..uri = getDestinationUri(mediaFile.media)
      ..media = mediaFile.media.toBuilder()
      ..etag = 'a1b2c3'
      ..lengthInBytes = mediaFile.file.lengthSync());
  }

  @override
  Uri getDestinationUri(Media media) {
    final key = getKey(media);
    return Uri.parse('$endpointUrl/$key');
  }

  @override
  Future<ServedMedia> getExistingServedMedia(Media media) async {
    final uri = getDestinationUri(media);
    var response = await client.head(uri);
    if (response.statusCode == 404) {
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
