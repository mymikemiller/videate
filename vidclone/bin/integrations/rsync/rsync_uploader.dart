import 'dart:io';
import 'package:vidlib/vidlib.dart' hide Platform;
import '../../uploader.dart';

// Base class for uploaders that use the rsync command to upload.
abstract class RsyncUploader extends Uploader {
  String get endpointUrl;
  final dynamic rsyncRunner;

  // We use dependency injection to allow for mocking the rsync command when
  // uploading
  RsyncUploader({this.rsyncRunner = Process.run});

  String getKey(Video video, [String extension = 'mp4']) {
    return 'videos/${video.source.platform.id}/${video.source.id}.$extension';
  }

  @override
  Future<ServedVideo> upload(VideoFile videoFile) async {
    final path = videoFile.file.path;
    final key = getKey(videoFile.video);
    final destinationFolderPath = key.substring(0, key.lastIndexOf('/') + 1);

    // rsync -e "ssh -i ~/.ssh/cdn77_id_rsa" /path/to/file user_amhl64ul@push-24.cdn77.com:/www/...
    final output = await Process.run('rsync', [
      '-e',
      'ssh -i ~/.ssh/cdn77_id_rsa',
      path,
      'user_amhl64ul@push-24.cdn77.com:/www/$destinationFolderPath',
    ]);

    if (output.stderr.isNotEmpty) {
      if (output.stderr.toString().contains('connection unexpectedly closed') &&
          output.stderr
              .toString()
              .contains('error in rsync protocol data stream')) {
        print(
            'rsync error may imply a missing directory structure at the destination. Try creating the "$destinationFolderPath" directory.');
      }
      throw 'process rsync error: ${output.stderr}';
    }

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

    final etag = response.headers['etag'];
    final length = int.parse(response.headers['content-length']);

    return ServedVideo((b) => b
      ..uri = getDestinationUri(video)
      ..video = video.toBuilder()
      ..etag = etag
      ..lengthInBytes = length);
  }

  @override
  void close() {
    client.close();
    // Do nothing
  }
}
