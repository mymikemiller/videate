import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';

void main() {
  group('Media', () {
    test('constructor', () {
      expect(Examples.media1.title, 'Media 1');
      expect(Examples.media1.description, 'Description 1');
      expect(Examples.media1.source.uri,
          Uri.parse('https://www.example.com/aaa111'));
      expect(Examples.media1.source.platform.id, 'example');
    });

    test('JSON serialization/deserialization', () async {
      await TestUtilities.testValueSerialization(Examples.media1,
          File('test/resources/media_1_serialized_expected.json'));
    });

    test('JSON serialization of lists', () async {
      await TestUtilities.testListSerialization(
          BuiltList<Media>.from([Examples.media1, Examples.media2]),
          File('test/resources/media_list_serialized_expected.json'));
    });
  });
}
