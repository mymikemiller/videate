// Generates an xml podcast feed given metadata about the videos in the feed.
// Also includes functions to analyze file contents to fill that feed.
import 'dart:io';
import 'package:xml/xml.dart';

/*
Example output:
<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
<channel>
<title>Podcast Title</title>
<link>http://www.example.com/<link>
<language>en-us</language>
<itunes:subtitle>Podcast Subtitle</itunes:subtitle>
<itunes:author>VidCast</itunes:author>
<itunes:summary>Podcast Summary</itunes:summary>
<description>Podcast Description</description>
<itunes:owner>
    <itunes:name>Mike Miller</itunes:name>
    <itunes:email>mike@example.com</itunes:email>
</itunes:owner>
<itunes:explicit>yes</itunes:explicit>
<itunes:image href="https://example.com/image.png" />
<itunes:category text="Category Name"/></itunes:category>

<!--REPEAT THIS BLOCK FOR EACH EPISODE-->
<item>
    <title>Title of Podcast Episode</title>
    <itunes:summary>Description of podcast episode content</itunes:summary>
    <description>Description of podcast episode content</description>
    <link>http://example.com/podcast-1</link>
    <enclosure url="" type="video/mpeg" length="1024"></enclosure>
    <pubDate>Thu, 21 Dec 2016 16:01:07 +0000</pubDate>
    <itunes:author>Author Name</itunes:author>
    <itunes:duration>00:32:16</itunes:duration>
    <itunes:explicit>yes</itunes:explicit>
    <guid>http://example.com/podcast-1</guid>
</item> 
<!--END REPEAT--> 
   
</channel>
</rss>
*/

class FeedGenerator {
  static XmlDocument generate(String hostname, Map feedData, String fileRoot) {
    var builder = new XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('rss', nest: () {
      builder.attribute(
          'xmlns:itunes', 'http://www.itunes.com/dtds/podcast-1.0.dtd');
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
        builder.element('itunes:explicit', nest: 'yes');
        builder.element('itunes:image', nest: () {
          builder.attribute('href', feedData['image']);
        });
        builder.element('itunes:category', nest: () {
          builder.attribute('text', 'Sexuality');
        });

        // Repeat for each episode
        for (final metadata in feedData['episodes']) {
          final fileName = metadata['file_path'];
          final servedPath = '$hostname/$fileName';
          final filePath = '$fileRoot/$fileName';
          final file = File(filePath);
          if (!file.existsSync()) {
            throw 'File not found: $filePath';
          }
          final shownotes =
              '<a href=${metadata['source_link']}>${metadata['source_link']}</a><br><br>${metadata['description']}';
          builder.element('item', nest: () {
            builder.element('title', nest: metadata['title']);
            builder.element('itunes:summary', nest: metadata['description']);
            builder.element('description', nest: shownotes);
            builder.element('link', nest: metadata['source_link']);
            builder.element('enclosure', nest: () {
              builder.attribute('url', servedPath);
              builder.attribute('type', 'video/mpeg');
              builder.attribute('length', file.lengthSync());
            });
            builder.element('pubDate', nest: metadata['date']);
            builder.element('itunes:author',
                nest: metadata['creators'].join(', '));
            builder.element('itunes:duration', nest: metadata['duration']);
            builder.element('itunes:explicit', nest: 'yes');
            builder.element('guid', nest: servedPath);
          });
        }
        ;
      });
    });
    return builder.build();
  }
}
