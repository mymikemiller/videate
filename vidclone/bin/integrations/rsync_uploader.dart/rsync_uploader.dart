import 'dart:io';
import 'package:vidlib/vidlib.dart';
import '../../uploader.dart';

// Base class for uploaders that use the rsync command to upload.
abstract class RsyncUploader extends Uploader {
  String get endpointUrl;
  final String username;
  final String password;

  final dynamic rsyncRunner;

  RsyncUploader(this.username, this.password, {this.rsyncRunner = Process.run});

  String getKey(Video video, [String extension = 'mp4']) {
    return 'videos/${video.source.platform.id}/${video.source.id}.$extension';
  }

  @override
  Future<ServedVideo> upload(VideoFile videoFile) async {
    final path = videoFile.file.path;
    final key = getKey(videoFile.video);
    final destinationFolderPath = key.substring(0, key.lastIndexOf('/') + 1);

    // rsync -e "ssh -i ~/.ssh/cdn77_id_rsa" /path/to/file user_amhl64ul@push-24.cdn77.com:/www/
    final output = await rsyncRunner('rsync', [
      '-e',
      '"ssh -i ~/.ssh/cdn77_id_rsa"',
      path,
      'user_amhl64ul@push-24.cdn77.com:/www/$destinationFolderPath',
    ]);

    if (output.stderr.isNotEmpty) {
      if (output.stderr.toString().contains('connection unexpectedly closed')) {
        print(
            'rsync error may imply a missing directory structure at the destination. Try creating the $destinationFolderPath directory.');
      }
      throw 'rsync error: ${output.stderr}';
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
    var request = await HttpClient().headUrl(uri);

    var response = await request.close();
    if (response.statusCode == 404) {
      // Video not found
      return null;
    }

    final etag = response.headers['etag'].first;
    final length = int.parse(response.headers['content-length'].first);

    return ServedVideo((b) => b
      ..uri = getDestinationUri(video)
      ..video = video.toBuilder()
      ..etag = etag
      ..lengthInBytes = length);
  }

  @override
  close() {
    // Do nothing
  }
}
