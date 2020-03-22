// Generates metdata for the feed generator from sources such as the videos in a folder
import 'dart:io';
import 'package:path/path.dart';

class MetadataGenerator {
  // hostedRootPath is the path to the root hosted folder, so urls will elide
  // this root path from the paths for the media files in the returned metadata
  static Map fromFolder(Directory dir, String hostedRootPath) {
    final folderName = basename(dir.uri.path);
    final Map metadata = {
      'title': folderName,
      'subtitle': 'Feed from \'$folderName\' folder',
      'link': 'http://www.example.com',
      'author': 'Mike Miller',
      'email': 'mike@example.com',
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
      // For now, only serve .mp4 files
      if (file.path.endsWith('.mp4')) {
        metadata['episodes'].add({
          'title': basename(file.path),
          'description': basenameWithoutExtension(file.path),
          'source_link': 'http://www.example.com',
          'file_path': file.path.replaceFirst(hostedRootPath, ''),
          'creators': ['Mike Miller'],
          'date': 'Wed, 01 Jan 2020 00:00:00 +0000',
          'duration': '01:00:00',
        });
      }
    }

    return metadata;
  }
}
