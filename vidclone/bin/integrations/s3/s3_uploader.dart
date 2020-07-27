import 'dart:io';

import 'package:aws_s3_client/aws_s3.dart';
import 'package:vidlib/vidlib.dart';
import '../../uploader.dart';

// Base class for uploaders that support the S3 protocol.
abstract class S3Uploader extends Uploader {
  String get endpointUrl;
  String get region => 'us-west-1';
  final String accessKey;
  final String secretKey;

  S3Uploader(this.accessKey, this.secretKey);

  // Get the s3 key (The "file name". The latter part of the url; does not
  // include the bucket name)
  String getKey(Video video, [String extension = 'mp4']) {
    final test = '4';
    return 'videate${test}/${video.source.platform.id}/${video.source.id}.$extension';
  }

  String getBucketName(Video video) {
    // All videos are currently in the same bucket. This is likely to change.
    return 'videate';
  }

  Bucket getBucket(Video video) {
    final bucketName = getBucketName(video);

    return Bucket(
        region: region,
        accessKey: accessKey,
        secretKey: secretKey,
        endpointUrl: 'http://$bucketName.$endpointUrl');
  }

  @override
  Future<ServedVideo> upload(VideoFile videoFile) async {
    // _uploadStream currently fails due to authentication issues. return
    // _uploadStream(videoFile);

    return _uploadFile(videoFile);
  }

  // Uploads the entire file at once
  Future<ServedVideo> _uploadFile(VideoFile videoFile) async {
    final bucket = getBucket(videoFile.video);
    final key = getKey(videoFile.video);
    final length = videoFile.file.lengthSync();
    final uri = getDestinationUri(videoFile.video);

    final etag = await bucket.uploadFile(
        key, videoFile.file.path, 'video/mp4', Permissions.public);

    final servedVideo = ServedVideo((b) => b
      ..video = videoFile.video.toBuilder()
      ..uri = uri
      ..etag = etag
      ..lengthInBytes = length);

    return servedVideo;
  }

  // Uploads the file in chunks. This is useful so the entire file does not
  // need to be read into memory all at once.
  Future<ServedVideo> _uploadStream(VideoFile videoFile) async {
    final bucket = getBucket(videoFile.video);
    final key = getKey(videoFile.video);
    final length = videoFile.file.lengthSync();

    // Dart complains about type mismatches unless we explicitly convert each
    // entry into a List<int> type, not Uint8List
    final Stream<List<int>> fileStream =
        videoFile.file.openRead().map((uInt8List) => List<int>.from(uInt8List));

    final etag = await bucket.uploadFileStream(
        key, fileStream, length, 'video/mp4', Permissions.public);

    final uri = getDestinationUri(videoFile.video);

    final servedVideo = ServedVideo((b) => b
      ..video = videoFile.video.toBuilder()
      ..uri = uri
      ..etag = etag
      ..lengthInBytes = videoFile.file.lengthSync());

    return servedVideo;
  }

  @override
  Uri getDestinationUri(Video video) {
    final bucketName = getBucketName(video);
    final key = getKey(video);
    return Uri.parse('http://$bucketName.$endpointUrl/$key');
  }

  @override
  Future<ServedVideo> getExistingServedVideo(Video video) async {
    final key = getKey(video);
    final bucket = getBucket(video);
    // var contents = await bucket.listContents(prefix: key, delimiter: '/');
    var contents = await bucket.listContents();
    final list = await contents.toList();

//start
    final num = 1;
    final uri = getDestinationUri(video);
    final etagFile = await bucket.uploadFile('test/file$num.txt',
        'test/resources/local/deleteme.txt', 'text/plain', Permissions.public);

    final file = File('test/resources/local/deleteme.txt');
    final length = file.lengthSync();
    // Dart complains about type mismatches unless we explicitly convert each
    // entry into a List<int> type, not Uint8List
    final Stream<List<int>> fileStream =
        file.openRead().map((uInt8List) => List<int>.from(uInt8List));
    final etagStream = await bucket.uploadFileStream('test/stream$num.txt',
        fileStream, length, 'text/plain', Permissions.public);
//end

    if (list.isEmpty) {
      return null;
    }

    // We always expect exactly one match for the specified key
    if (list.length > 1) {
      throw 'Only one entry at key $key expected. ${list.length} found.';
    }

    final match = list[0];

    return ServedVideo((b) => b
      ..uri = getDestinationUri(video)
      ..video = video.toBuilder()
      ..etag = match.eTag
      ..lengthInBytes = match.size);
  }
}
