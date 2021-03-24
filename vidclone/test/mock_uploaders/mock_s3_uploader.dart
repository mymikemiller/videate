/* Deprecated until we need an S3 uploader

import 'dart:io';
import 'package:mockito/mockito.dart';
import 'package:vidlib/vidlib.dart';
import '../../bin/integrations/s3/s3_uploader.dart';
import 'package:aws_s3_client/aws_s3.dart';
import 'dart:typed_data';

/// This uploader emulates uploading to s3 by storing uploaded data in memory
/// instead of making any http requests
class MockS3Uploader extends S3Uploader {
  @override
  String get id => 's3';

  final Bucket _bucket = FakeS3Bucket();

  @override
  Bucket getBucket(Media media) => _bucket;

  MockS3Uploader() : super('TEST', 'TEST');

  @override
  String get endpointUrl => 'http://example.com';
}

// This fake bucket holds on to all uploaded data in memory instead of
// uploading it to s3.
class FakeS3Bucket extends Fake implements Bucket {
  Map<String, Uint8List> uploads = {};

  @override
  Future<String> uploadFile(
      String key, String filePath, String contentType, Permissions permissions,
      {Map<String, String> meta}) async {
    final file = File(filePath);
    uploads[key] = file.readAsBytesSync();
    return 'a1b2c3';
  }

  @override
  Stream<BucketContent> listContents(
      {String delimiter, String prefix, int maxKeys}) async* {
    yield* Stream.fromIterable(uploads.entries.map((upload) => BucketContent(
        key: upload.key,
        lastModifiedUtc: DateTime.fromMillisecondsSinceEpoch(0),
        eTag: 'a1b2c3',
        size: upload.value.length)));
  }
}
*/
