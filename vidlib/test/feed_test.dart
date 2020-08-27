import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';

void main() {
  group('Feed', () {
    test('constructor', () {
      expect(Examples.feed1.title, 'Test Feed 1');
      expect(Examples.feed1.subtitle, 'Subtitle 1');
      expect(Examples.feed1.description, 'Description 1');
      expect(Examples.feed1.mediaList,
          [Examples.servedMedia1, Examples.servedMedia2]);
    });

    test('JSON serialization/deserialization', () {
      TestUtilities.testValueSerialization(Examples.feed1,
          File('test/resources/feed_1_serialized_expected.json'));
    });

    test('JSON serialization of lists', () async {
      await TestUtilities.testListSerialization(
          BuiltList<Feed>.from([Examples.feed1, Examples.feed2]),
          File('test/resources/feeds_serialized_expected.json'));
    });
  });
}
