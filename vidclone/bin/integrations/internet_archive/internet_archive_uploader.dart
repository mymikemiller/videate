// Uploads videos to archive.org
import '../s3/s3_uploader.dart';

/// Uploads the video to archive.org.
///
/// Note that the video will take some time to process (From experience, ten
/// minutes, though the site says it could take up to 24 hours). During this
/// time, attempting to access the file via the url will produce a 404
/// "NoSuchKey" error. This is distinct from a 404 NoSuchBucket error, which
/// occurs for random URLs that are not in progress.
class InternetArchiveUploader extends S3Uploader {
  InternetArchiveUploader(String accessKey, String secretKey)
      : super(accessKey, secretKey);

  @override
  String get id => 'internet_archive';

  @override
  String get endpointUrl => 'http://s3.us.archive.org';

  @override
  String get authorizationHeader => 'LOW $accessKey:$secretKey';
}
