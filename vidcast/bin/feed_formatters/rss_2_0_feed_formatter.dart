// Generates an xml podcast feed given metadata about the videos in the feed.
// Also includes functions to analyze file contents to fill that feed.
import 'package:xml/xml.dart';
import 'package:mime/mime.dart';
import 'package:vidlib/vidlib.dart';
import 'package:path/path.dart' as p;
import 'feed_formatter.dart';

// See test resources for expected output
class RSS_2_0_FeedFormatter extends FeedFormatter<XmlDocument> {
  final String servedMediaBaseUri;

  // servedMediaBaseUrl will be prepended to the URIs to the video files
  RSS_2_0_FeedFormatter(this.servedMediaBaseUri);

  XmlDocument format(Feed feed) {
    var builder = new XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('rss', nest: () {
      builder.attribute(
          'xmlns:itunes', 'http://www.itunes.com/dtds/podcast-1.0.dtd');
      builder.attribute(
          'xmlns:content', 'http://purl.org/rss/1.0/modules/content/');
      builder.attribute('version', '2.0');
      builder.element('channel', nest: () {
        builder.element('title', nest: feed.title);
        builder.element('link', nest: feed.link);
        builder.element('language', nest: 'en-us');
        builder.element('itunes:subtitle', nest: feed.subtitle);
        builder.element('itunes:author', nest: feed.author);
        builder.element('itunes:summary', nest: feed.description);
        builder.element('description', nest: feed.description);
        builder.element('itunes:owner', nest: () {
          builder.element('itunes:name', nest: feed.author);
          builder.element('itunes:email', nest: feed.email);
        });
        builder.element('itunes:explicit', nest: 'no');
        builder.element('itunes:image', nest: () {
          builder.attribute('href', feed.imageUrl);
        });
        builder.element('itunes:category', nest: () {
          builder.attribute('text', 'Arts');
        });

        // Repeat for each episode
        for (final video in feed.videos) {
          final servedPath = video.uri.isAbsolute
              ? video.uri.toString()
              : p.join(servedMediaBaseUri, video.uri.toString());

          // TODO: Bring back 'creators' // <a href=$baseUrl/tip?creator="${video.video.creators[0]}">Tip \$1</a><br><br>
          final shownotes =
              '<a href=${video.video.source.releaseDate}>${video.video.source.uri}</a><br><br>${video.video.description}';

          builder.element('item', nest: () {
            builder.element('title', nest: video.video.title);
            builder.element('itunes:summary', nest: video.video.description);
            builder.element('description', nest: video.video.description);
            builder.element('content:encoded', nest: () {
              // Use cdata here to avoid having to escape "<", ">" and "&"
              builder.cdata(shownotes);
            });
            builder.element('link', nest: video.video.source.uri.toString());
            builder.element('enclosure', nest: () {
              builder.attribute('url', servedPath);
              builder.attribute('type', lookupMimeType(video.uri.path));
              builder.attribute('length', video.lengthInBytes);
            });
            builder.element('pubDate', nest: video.video.source.releaseDate);
            builder.element('itunes:author',
                nest: video.video.creators.join(', '));
            builder.element('itunes:duration',
                nest: video.video.duration.toString());
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
