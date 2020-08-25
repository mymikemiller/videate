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

  String getKey(Video video, [String extension = 'mp4']) {
    return 'videos/${video.source.platform.id}/${video.source.id}.$extension';
  }

  @override
  Future<ServedVideo> upload(VideoFile videoFile) async {
    final key = getKey(videoFile.video);
    await push(videoFile.file, key);

    return ServedVideo((b) => b
      ..uri = getDestinationUri(videoFile.video)
      ..video = videoFile.video.toBuilder()
      ..etag = 'a1b2c3'
      ..lengthInBytes = videoFile.file.lengthSync());
  }

  @override
  Uri getDestinationUri(Video video) {
    final key = getKey(video);
    return Uri.parse('$endpointUrl/$key');
  }

  @override
  Future<ServedVideo> getExistingServedVideo(Video video) async {
    final uri = getDestinationUri(video);
    var response = await client.head(uri);
    if (response.statusCode == 404) {
      // Video not found
      return null;
    }
    if (response.statusCode != 200) {
      throw 'received unexpected status code: ${response.statusCode}';
    }

    final etag = response.headers['etag'];
    final length = int.parse(response.headers['content-length']);

    return ServedVideo((b) => b
      ..uri = getDestinationUri(video)
      ..video = video.toBuilder()
      ..etag = etag
      ..lengthInBytes = length);
  }
}
