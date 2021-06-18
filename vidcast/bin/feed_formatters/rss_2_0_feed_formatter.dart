/* Removed in favor of generating feeds on the Internet Computer (see credits 
   folder)

// Generates an xml podcast feed given metadata about the media in the feed.
// Also includes functions to analyze file contents to fill that feed.

import 'package:xml/xml.dart';
import 'package:mime/mime.dart';
import 'package:vidlib/vidlib.dart';
import 'feed_formatter.dart';

// See test resources for expected output
class RSS_2_0_FeedFormatter extends FeedFormatter<XmlDocument> {
  RSS_2_0_FeedFormatter(List<UriTransformer> uriTransformers)
      : super(uriTransformers);

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

        // Repeat for each episode, starting with the most recent
        for (final media in feed.mediaList.reversed) {
          final uri = transformUri(media.uri);

          // TODO: Bring back 'creators' // <a href=$baseUrl/tip?creator="${media.media.creators[0]}">Tip \$1</a><br><br>
          final shownotes =
              '<a href=${media.media.source.releaseDate}>${uri}</a><br><br>${media.media.description}';

          builder.element('item', nest: () {
            builder.element('title', nest: media.media.title);
            builder.element('itunes:summary', nest: media.media.description);
            builder.element('description', nest: media.media.description);
            builder.element('content:encoded', nest: () {
              // Use cdata here to avoid having to escape "<", ">" and "&"
              builder.cdata(shownotes);
            });
            builder.element('link', nest: uri);
            builder.element('enclosure', nest: () {
              builder.attribute('url', uri);
              builder.attribute('type', lookupMimeType(media.uri.path));
              builder.attribute('length', media.lengthInBytes);
            });
            builder.element('pubDate', nest: media.media.source.releaseDate);
            builder.element('itunes:author',
                nest: media.media.creators.join(', '));
            builder.element('itunes:duration',
                nest: media.media.duration.toString());
            builder.element('itunes:explicit', nest: 'no');
            builder.element('guid', nest: uri);
          });
        }
        ;
      });
    });
    return builder.build() as XmlDocument;
  }
}
*/
