import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';
import 'serialization_testing.dart';

void main() {
  group('Video', () {
    test('constructor', () {
      expect(Examples.video1.title, 'Video 1');
      expect(Examples.video1.description, 'Description 1');
      expect(Examples.video1.sourceUrl, 'https://www.example.com/1');
    });

    test('JSON serialization/deserialization', () async {
      await testValueSerialization(Examples.video1,
          File('test/resources/video_1_serialized_expected.json'));
    });

    test('JSON serialization of lists', () async {
      await testListSerialization(
          BuiltList<Video>.from([Examples.video1, Examples.video2]),
          File('test/resources/videos_serialized_expected.json'));
    });
  });
}
