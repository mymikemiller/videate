import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:xml/xml.dart' as xml;
import '../bin/metadata_generator.dart';
import '../bin/feed_generator.dart';

void expectXmlEqual(xml.XmlDocument observed, xml.XmlDocument expected) {
  final formatXml = (xml.XmlDocument input) => input
      .toXmlString(pretty: true)
      .replaceFirst('<?xml version="1.0"?>', '<?xml version="1.0" ?>');
  final formattedObserved = formatXml(observed);
  final formattedExpected = formatXml(expected);
  expect(formattedObserved, formattedExpected);
}

void main() async {
  group('MetadataGenerator', () {
    test('generates json metadata from videos in a directory', () async {
      final directory = Directory('test/resources/videos');
      final feedData =
          await MetadataGenerator.fromFolder(directory, 'test/www/videos');

      final expectedMetadataFile =
          File('test/resources/expected_feed_metadata.json');
      final expectedJson = await expectedMetadataFile.readAsString();
      final expectedFeedData = jsonDecode(expectedJson);
      expect(feedData, expectedFeedData);
    });
  });
  group('FeedGenerator', () {
    test('generates feed from json metadata', () async {
      final testMetadataFile = File('test/resources/test_feed_metadata.json');
      final testJson = await testMetadataFile.readAsString();
      final testFeedData = jsonDecode(testJson);
      final testFeed = FeedGenerator.generate('http://example.com',
          testFeedData, '${Directory.current.path}/test/resources/videos');

      final expectedFile = File('test/resources/test_feed_expected.xml');
      final expectedXml = await expectedFile.readAsString();
      final expectedFeed = xml.parse(expectedXml);

      expectXmlEqual(testFeed, expectedFeed);
    });
  });
}
