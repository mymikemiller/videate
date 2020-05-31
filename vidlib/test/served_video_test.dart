import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';
import 'serialization_testing.dart';

void main() {
  group('ServedVideo', () {
    test('constructor', () {
      expect(Examples.servedVideo1.video, Examples.video1);
      expect(Examples.servedVideo1.uri, Uri(path: '/test/video1.mp4'));
      expect(Examples.servedVideo1.lengthInBytes, 100000);
    });

    test('JSON serialization/deserialization', () async {
      await testValueSerialization(Examples.servedVideo1,
          File('test/resources/served_video_1_serialized_expected.json'));
    });

    test('JSON serialization of lists', () async {
      await testListSerialization(
          BuiltList<ServedVideo>.from(
              [Examples.servedVideo1, Examples.servedVideo2]),
          File('test/resources/served_videos_serialized_expected.json'));
    });
  });
}
