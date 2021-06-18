/* Removed in favor of generating feeds on the Internet Computer (see credits
 folder)
 

import 'dart:io';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import '../bin/feed_formatters/rss_2_0_feed_formatter.dart';

void main() async {
  group('RSS feeds', () {
    final uriTransformer = (Uri input) => Uri.parse(input
        .toString()
        .replaceFirst('test/resources/media', 'https://example.com'));

    final feedFormatter = RSS_2_0_FeedFormatter([uriTransformer]);
    test('generate properly', () async {
      final testMetadataFile = File('test/resources/test_feed_metadata.json');
      final testJson = await testMetadataFile.readAsString();
      final feed = Feed.fromJson(testJson);
      final testFeed = feedFormatter.format(feed);
      final expectedFile = File('test/resources/rss_2_0_feed_expected.xml');

      TestUtilities.testXml(testFeed, expectedFile);
    });
  });
}

*/
