// Generates an xml podcast feed given metadata about the videos in the feed.
// Also includes functions to analyze file contents to fill that feed.
import 'dart:io';
import 'package:xml/xml.dart';
import 'package:mime/mime.dart';

// See test resources for expected output
class FeedGenerator {
  static XmlDocument generate(Map feedData, String baseUrl, String fileRoot) {
    var builder = new XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('rss', nest: () {
      builder.attribute(
          'xmlns:itunes', 'http://www.itunes.com/dtds/podcast-1.0.dtd');
      builder.attribute(
          'xmlns:content', 'http://purl.org/rss/1.0/modules/content/');
      builder.attribute('version', '2.0');
      builder.element('channel', nest: () {
        builder.element('title', nest: feedData['title']);
        builder.element('link', nest: feedData['link']);
        builder.element('language', nest: 'en-us');
        builder.element('itunes:subtitle', nest: feedData['subtitle']);
        builder.element('itunes:author', nest: feedData['author']);
        builder.element('itunes:summary', nest: feedData['description']);
        builder.element('description', nest: feedData['description']);
        builder.element('itunes:owner', nest: () {
          builder.element('itunes:name', nest: feedData['author']);
          builder.element('itunes:email', nest: feedData['email']);
        });
        builder.element('itunes:explicit', nest: 'no');
        builder.element('itunes:image', nest: () {
          builder.attribute('href', feedData['image']);
        });
        builder.element('itunes:category', nest: () {
          builder.attribute('text', 'Arts');
        });

        // Repeat for each episode
        for (final metadata in feedData['episodes']) {
          final fileName = metadata['file_path'];
          final servedPath = '$baseUrl/$fileName';
          final filePath = '$fileRoot/$fileName';
          final file = File(filePath);
          if (!file.existsSync()) {
            throw 'File not found: $filePath';
          }

          final shownotes =
              '<a href=$baseUrl/tip?creator="${metadata['creators'][0]}">Tip \$1</a><br><br><a href=${metadata['source_link']}>${metadata['source_link']}</a><br><br>${metadata['description']}';

          builder.element('item', nest: () {
            builder.element('title', nest: metadata['title']);
            builder.element('itunes:summary', nest: metadata['description']);
            builder.element('description', nest: metadata['description']);
            builder.element('content:encoded', nest: () {
              // Use cdata here to avoid having to escape "<", ">" and "&"
              builder.cdata(shownotes);
            });
            builder.element('link', nest: metadata['source_link']);
            builder.element('enclosure', nest: () {
              builder.attribute('url', servedPath);
              builder.attribute('type', lookupMimeType(file.path));
              builder.attribute('length', file.lengthSync());
            });
            builder.element('pubDate', nest: metadata['date']);
            builder.element('itunes:author',
                nest: metadata['creators'].join(', '));
            builder.element('itunes:duration', nest: metadata['duration']);
            builder.element('itunes:explicit', nest: 'no');
            builder.element('guid', nest: servedPath);
          });
        }
        ;
      });
    });
    return builder.build();
  }
}
