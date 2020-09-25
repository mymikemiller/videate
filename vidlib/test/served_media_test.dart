import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';

void main() {
  group('ServedMedia', () {
    test('constructor', () {
      expect(Examples.servedMedia1.media, Examples.media1);
      expect(Examples.servedMedia1.uri, Uri(path: '/test/video1.mp4'));
      expect(Examples.servedMedia1.lengthInBytes, 100000);
    });

    test('JSON serialization/deserialization', () async {
      await TestUtilities.testValueSerialization(Examples.servedMedia1,
          File('test/resources/served_media_1_serialized_expected.json'));
    });

    test('JSON serialization of lists', () async {
      await TestUtilities.testListSerialization(
          BuiltList<ServedMedia>.from(
              [Examples.servedMedia1, Examples.servedMedia2]),
          File('test/resources/served_media_list_serialized_expected.json'));
    });
  });
}
