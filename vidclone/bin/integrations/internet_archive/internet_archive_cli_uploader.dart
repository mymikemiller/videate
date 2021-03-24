import 'dart:convert';
import 'dart:math';

import 'package:vidlib/src/models/served_media.dart';
import 'package:vidlib/src/models/media_file.dart';
import 'package:vidlib/src/models/media.dart';
import 'package:vidlib/vidlib.dart';
import '../../uploader.dart';

/// Uses Internet Archive's 'ia' command line tool
/// (https://github.com/jjjake/internetarchive) to uploads the media to
/// archive.org.
///
/// Note that the media will take some time to process (From experience, ten
/// minutes, though the site says it could take up to 24 hours). During this
/// time, attempting to access the file via the url will produce a 404
/// "NoSuchKey" error. This is distinct from a 404 NoSuchBucket error, which
/// occurs for random URLs that are not in progress.
class InternetArchiveCliUploader extends Uploader {
  InternetArchiveCliUploader(String accessKey, String secretKey);

  @override
  String get id => 'internet_archive_cli';

  String credentialsFilePath;

  @override
  void configure(ClonerTaskArgs args) {
    credentialsFilePath = args.get('credentialsFile');
  }

  // Get the archive.org identifier (The "file name" without the extension. The
  // latter part of the url. This is duplicated verbatim in the url, the second
  // )
  String getIdentifier(Media media) {
    // No need to repeat the source's id if that's also the title
    final title = media.title == media.source.id ? '' : '_${media.title}';
    final base =
        'videate_${media.source.platform.id}_${media.source.id}${title}';

    // Internet Archive only allows alphanumeric characters plus underscores,
    // dashes and periods. See
    // https://archive.org/services/docs/api/metadata-schema/#archive-org-identifiers
    final underscored = base.replaceAll(' ', '_');
    final sanitized = underscored.replaceAll(RegExp(r'[^A-Za-z0-9_\-\.]'), '');

    // Internet Archive recommends that identifiers be 80 characters or less
    // (though they are allowed to be up to 100 characters)
    return sanitized.substring(0, min(sanitized.length, 80));
  }

  @override
  Uri getDestinationUri(Media media) {
    final identifier = getIdentifier(media);
    return Uri.parse(
        'https://archive.org/download/$identifier/$identifier.mp4');
  }

  @override
  Future<ServedMedia> uploadMedia(MediaFile mediaFile,
      [Function(double progress) callback]) async {
    final identifier = getIdentifier(mediaFile.media);
    final file = await ensureLocal(mediaFile.file);

    final args = [
      '--config-file',
      '$credentialsFilePath',
      'upload',
      '$identifier',
      '${file.path}',
      '--remote-name=$identifier.mp4',
      '--size-hint=${file.lengthSync()}',
      '--no-derive',
      '--metadata=mediatype:movies',
      '--metadata=collection:opensource_movies',
    ];
    await processStarter('./bin/integrations/internet_archive/ia', args)
        .then((p) async {
      p.stderr.transform(Utf8Decoder()).listen((String data) {
        if (data.contains('This item has been taken offline')) {
          // Probably shouldn't throw here, but for now it's ok as this only
          // happens when the user deletes a video off ia, then tries to
          // reupload with the same name. TODO: add retry logic that
          // automatically changes the name
          throw ('Upload failed. A video with the same name was probably previously deleted from this internet archive account. Consider changing the name and retrying.');
        }

        final progressRegex = RegExp(r'(\d+)%');
        final progressMatch = progressRegex.firstMatch(data);
        if (progressMatch != null) {
          final progress = double.parse(progressMatch.group(1)) / 100.0;
          callback?.call(progress);
        }
      });

      final exitCode = await p.exitCode;
      if (exitCode != 0) {
        throw '$id upload error (exit code $exitCode)';
      }
    });
    return ServedMedia((b) => b
      ..uri = getDestinationUri(mediaFile.media)
      ..media = mediaFile.media.toBuilder()
      ..etag = 'ia_a1b2c3'
      ..lengthInBytes = mediaFile.file.lengthSync());
  }
}
