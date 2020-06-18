import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import '../bin/feed_formatters/rss_2_0_feed_formatter.dart';

void main() async {
  group('RSS feeds', () {
    final feedFormatter = RSS_2_0_FeedFormatter('https://example.com');
    test('generate properly', () async {
      final testMetadataFile = File('test/resources/test_feed_metadata.json');
      final testJson = await testMetadataFile.readAsString();
      final data = jsonDecode(testJson);
      final feed = Feed.fromJson(data);
      final testFeed = feedFormatter.format(feed);
      final expectedFile = File('test/resources/rss_2_0_feed_expected.xml');

      TestUtilities.testXml(testFeed, expectedFile);
    });
  });
}
