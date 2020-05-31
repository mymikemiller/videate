import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import 'package:xml/xml.dart' as xml;
import '../bin/feed_formatters/rss_2_0_feed_formatter.dart';

void expectXmlEqual(xml.XmlDocument observed, xml.XmlDocument expected) {
  final formatXml = (xml.XmlDocument input) => input
      .toXmlString(pretty: true)
      .replaceFirst('<?xml version="1.0"?>', '<?xml version="1.0" ?>');
  final formattedObserved = formatXml(observed);
  final formattedExpected = formatXml(expected);
  expect(formattedObserved, formattedExpected);
}

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
      final expectedXml = await expectedFile.readAsString();
      final expectedFeed = xml.parse(expectedXml);

      expectXmlEqual(testFeed, expectedFeed);
    });
  });
}
