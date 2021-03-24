/* Deprecated until we need an S3 uploader

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
  String getKey(Media media, [String extension = 'mp4']) {
    final test = '4';
    // todo: Maybe this isn't working because archive.org identifiers are not
    // allowed to have slashes in them. That might be what's tripping the
    // authentication error. See
    // https://archive.org/services/docs/api/metadata-schema/#archive-org-identifiers
    return 'videate${test}/${media.source.platform.id}/${media.source.id}.$extension';
  }

  String getBucketName(Media media) {
    // All media are currently in the same bucket. This is likely to change.
    return 'videate';
  }

  Bucket getBucket(Media media) {
    final bucketName = getBucketName(media);

    return Bucket(
        region: region,
        accessKey: accessKey,
        secretKey: secretKey,
        endpointUrl: 'http://$bucketName.$endpointUrl');
  }

  @override
  Future<ServedMedia> uploadMedia(MediaFile mediaFile,
      [Function(double progress) callback]) async {
    // _uploadStream currently fails due to authentication issues.
    // return _uploadStream(mediaFile);

    return _uploadFile(mediaFile);
  }

  // Uploads the entire file at once
  Future<ServedMedia> _uploadFile(MediaFile mediaFile) async {
    final bucket = getBucket(mediaFile.media);
    final key = getKey(mediaFile.media);
    final length = mediaFile.file.lengthSync();
    final uri = getDestinationUri(mediaFile.media);

    final etag = await bucket.uploadFile(
        key, mediaFile.file.path, 'video/mp4', Permissions.public);

    final servedMedia = ServedMedia((b) => b
      ..media = mediaFile.media.toBuilder()
      ..uri = uri
      ..etag = etag
      ..lengthInBytes = length);

    return servedMedia;
  }

  // Uploads the file in chunks. This is useful so the entire file does not
  // need to be read into memory all at once.
  Future<ServedMedia> _uploadStream(MediaFile mediaFile) async {
    final bucket = getBucket(mediaFile.media);
    final key = getKey(mediaFile.media);
    final length = mediaFile.file.lengthSync();

    // Dart complains about type mismatches unless we explicitly convert each
    // entry into a List<int> type, not Uint8List
    final Stream<List<int>> fileStream =
        mediaFile.file.openRead().map((uInt8List) => List<int>.from(uInt8List));

    final etag = await bucket.uploadFileStream(
        key, fileStream, length, 'video/mp4', Permissions.public);

    final uri = getDestinationUri(mediaFile.media);

    final servedMedia = ServedMedia((b) => b
      ..media = mediaFile.media.toBuilder()
      ..uri = uri
      ..etag = etag
      ..lengthInBytes = mediaFile.file.lengthSync());

    return servedMedia;
  }

  @override
  Uri getDestinationUri(Media media) {
    final bucketName = getBucketName(media);
    final key = getKey(media);
    return Uri.parse('http://$bucketName.$endpointUrl/$key');
  }

  @override
  Future<ServedMedia> getExistingServedMedia(Media media) async {
    final key = getKey(media);
    final bucket = getBucket(media);
    // var contents = await bucket.listContents(prefix: key, delimiter: '/');
    var contents = await bucket.listContents();
    final list = await contents.toList();

    if (list.isEmpty) {
      return null;
    }

    // We always expect exactly one match for the specified key
    if (list.length > 1) {
      throw 'Only one entry at key $key expected. ${list.length} found.';
    }

    final match = list[0];

    return ServedMedia((b) => b
      ..uri = getDestinationUri(media)
      ..media = media.toBuilder()
      ..etag = match.eTag
      ..lengthInBytes = match.size);
  }
}
*/
