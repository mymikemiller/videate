import 'dart:io';

import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import '../../bin/integrations/s3/s3_uploader.dart';
import 'package:aws_s3_client/aws_s3.dart';
import 'dart:typed_data';

/// This uploader emulates uploading to s3 by storing uploaded data in memory
/// instead of making any http requests
class MockS3Uploader extends S3Uploader {
  @override
  String get id => 's3';

  final FakeS3Bucket _bucket = FakeS3Bucket();
  @override
  Bucket get bucket => _bucket;

  @override
  Future<Response> httpGet(uri, {Map<String, String> headers}) {
    final key = getKey(uri);
    final data = (bucket as FakeS3Bucket).uploads[key];
    if (data != null) {
      return Future.value(Response(data.toString(), 200));
    } else {
      return Future.value(Response('', 404));
    }
  }

  MockS3Uploader() : super('TEST', 'TEST');

  @override
  String get authorizationHeader => 'TEST';

  @override
  String get endpointUrl => 'http://example.com';

  @override
  void close() {
    // do nothing
  }
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

  // @override listContent() {}
}
