// Generates metdata for the feed generator from sources such as the videos in a folder
import 'dart:io';
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:vidlib/vidlib.dart';

class MetadataGenerator {
  // Generates metadata json with from the videos in a folder. Some values are
  // placeholders since not everything can be determined simply from the video
  // files themselves.
  // hostedRootPath is the path to the root hosted folder, so urls will elide
  // this root path from the paths for the media files in the returned metadata.
  // ffprobeRunner can be set to a stubbed function for testing on machines
  // that don't have ffprobe installed.
  static Future<Map> fromFolder(Directory dir, String hostedRootPath,
      {ffprobeRunner = Process.run}) async {
    final folderName = basename(dir.uri.path);
    final Map metadata = {
      'title': folderName,
      'subtitle': 'Feed from \'$folderName\' folder',
      'link': 'http://www.videate.org',
      'author': 'Mike Miller',
      'email': 'mike@videate.org',
      'description': 'Podcast feed of files in a hosted folder',
      'image':
          'https://media.istockphoto.com/vectors/folder-icon-with-a-rss-feed-sign-vector-id483567250',
      'episodes': []
    };

    final files = dir.listSync(recursive: false);

    // Order by date modified so if new videos are added, they'll appear at the end of the list
    files
        .sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

    for (FileSystemEntity file in files) {
      // Only serve video files
      if (lookupMimeType(file.path).startsWith('video')) {
        final duration = await getDuration(file, processRunner: ffprobeRunner);
        final durationString = duration.toString();

        metadata['episodes'].add({
          'title': basename(file.path),
          'description': basenameWithoutExtension(file.path),
          'source_link': 'http://www.videate.org',
          'file_path': file.path.replaceFirst(hostedRootPath, ''),
          'creators': ['Mike Miller'],
          'date': 'Wed, 01 Jan 2020 00:00:00 +0000',
          'duration': durationString.substring(0, durationString.indexOf('.')),
        });
      }
    }

    return metadata;
  }
}
