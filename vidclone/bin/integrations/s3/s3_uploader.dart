import 'package:aws_s3_client/aws_s3_client.dart';
import 'package:vidlib/vidlib.dart';
import 'package:path/path.dart' as p;
import '../../uploader.dart';

// Base class for uploaders that support the S3 protocol.
abstract class S3Uploader extends Uploader {
  String get endpointUrl;
  String get region => 'us-west-1';
  String get authorizationHeader;
  Bucket bucket;
  final String accessKey;
  final String secretKey;

  S3Uploader(this.accessKey, this.secretKey) {
    bucket = Bucket(
        region: region,
        accessKey: accessKey,
        secretKey: secretKey,
        endpointUrl: endpointUrl);
  }

  @override
  Future<ServedVideo> upload(VideoFile videoFile) async {
    final uri = getDestinationUri(videoFile.video);
    final key =
        uri.path.startsWith('/') ? uri.path.replaceFirst('/', '') : uri.path;
    final etag = await bucket.uploadFile(
        key, videoFile.file.readAsBytesSync(), 'video/mp4', Permissions.public);

    final servedVideo = ServedVideo((b) => b
      ..video = videoFile.video.toBuilder()
      ..uri = uri
      ..etag = etag
      ..lengthInBytes = videoFile.file.lengthSync());

    return servedVideo;
  }

  @override
  Uri getDestinationUri(Video video, [extension = 'mp4']) {
    final test = '3';
    final name =
        'videate${test}_${video.source.platform.id}_${video.source.id}';
    return Uri.parse('$endpointUrl/$name/$name.$extension');
  }
}
