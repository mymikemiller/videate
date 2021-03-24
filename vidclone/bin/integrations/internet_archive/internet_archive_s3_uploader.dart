/* Deprecated in favor of internet_archive_cli_uploader

// Uploads media to archive.org
import '../s3/s3_uploader.dart';

/// Uploads the media to archive.org.
///
/// Note that the media will take some time to process (From experience, ten
/// minutes, though the site says it could take up to 24 hours). During this
/// time, attempting to access the file via the url will produce a 404
/// "NoSuchKey" error. This is distinct from a 404 NoSuchBucket error, which
/// occurs for random URLs that are not in progress.
class InternetArchiveS3Uploader extends S3Uploader {
  InternetArchiveS3Uploader(String accessKey, String secretKey)
      : super(accessKey, secretKey);

  @override
  String get id => 'internet_archive_s3';

  @override
  String get endpointUrl => 's3.us.archive.org';
}
*/
