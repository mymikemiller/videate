import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';

void main() {
  group('Video', () {
    test('constructor', () {
      expect(Examples.video1.title, 'Video 1');
      expect(Examples.video1.description, 'Description 1');
      expect(Examples.video1.source.uri,
          Uri.parse('https://www.example.com/aaa111'));
      expect(Examples.video1.source.platform.id, 'example');
    });

    test('JSON serialization/deserialization', () async {
      await TestUtilities.testValueSerialization(Examples.video1,
          File('test/resources/video_1_serialized_expected.json'));
    });

    test('JSON serialization of lists', () async {
      await TestUtilities.testListSerialization(
          BuiltList<Video>.from([Examples.video1, Examples.video2]),
          File('test/resources/videos_serialized_expected.json'));
    });
  });
}
