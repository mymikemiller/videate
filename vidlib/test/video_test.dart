import 'dart:convert' show json;
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';

void main() {
  group('Video', () {
    Video video1;
    Video video2;
    BuiltList<Video> videos;

    setUp(() {
      video1 = Video((b) => b
        ..title = 'Test Title 1'
        ..description = 'Description 1'
        ..sourceUrl = 'https://www.example.com/1'
        ..sourceReleaseDate = DateTime.fromMillisecondsSinceEpoch(0).toUtc()
        ..creators = BuiltList<String>(['Mike Miller']).toBuilder()
        ..duration = Duration(minutes: 1));

      video2 = Video((b) => b
        ..title = 'Test Title 2'
        ..description = 'Description 2'
        ..sourceUrl = 'https://www.example.com/2'
        ..sourceReleaseDate = DateTime.fromMillisecondsSinceEpoch(0).toUtc()
        ..creators = BuiltList<String>(['Mike Miller']).toBuilder()
        ..duration = Duration(minutes: 2));

      videos = BuiltList.from([video1, video2]);
    });

    test('constructor', () {
      expect(video1.title, 'Test Title 1');
      expect(video1.description, 'Description 1');
      expect(video1.sourceUrl, 'https://www.example.com/1');
      expect(
          video1.sourceReleaseDate, DateTime.parse('1970-01-01T00:00:00.000Z'));
    });

    test('constructor throws error for non-UTC dates', () {
      expect(
          () => Video((b) => b
            ..title = 'Test Title 1'
            ..description = 'Description 1'
            ..sourceUrl = 'https://www.example.com/1'
            ..sourceReleaseDate = DateTime.fromMillisecondsSinceEpoch(0)
            ..creators = BuiltList<String>(['Mike Miller']).toBuilder()
            ..duration = Duration(minutes: 3)),
          throwsArgumentError);
    });

    test('JSON serialization/deserialization', () {
      final serialized = jsonSerializers.serialize(video1);
      final serializedExpected = {
        r'$': 'Video',
        'title': 'Test Title 1',
        'description': 'Description 1',
        'sourceUrl': 'https://www.example.com/1',
        'sourceReleaseDate': '1970-01-01T00:00:00.000Z',
        'creators': ['Mike Miller'],
        'duration': '0:01:00.000000',
      };
      expect(serialized, serializedExpected);

      final deserialized = jsonSerializers.deserialize(serialized);
      expect(deserialized, video1);
    });

    test('JSON serialization of lists', () {
      // Note that to support automatic deserialization of lists no matter
      // where they appear in the json, the built_value/built_collection
      // serializer puts the list inside an object under an empty string key.
      // See https://github.com/google/built_value.dart/issues/404

      // Test serialization to encodable object
      final serialized = jsonSerializers.serialize(videos);
      final serializedExpected = {
        r'$': 'list',
        '': [
          {
            r'$': 'Video',
            'title': 'Test Title 1',
            'description': 'Description 1',
            'sourceUrl': 'https://www.example.com/1',
            'sourceReleaseDate': '1970-01-01T00:00:00.000Z',
            'creators': ['Mike Miller'],
            'duration': '0:01:00.000000',
          },
          {
            r'$': 'Video',
            'title': 'Test Title 2',
            'description': 'Description 2',
            'sourceUrl': 'https://www.example.com/2',
            'sourceReleaseDate': '1970-01-01T00:00:00.000Z',
            'creators': ['Mike Miller'],
            'duration': '0:02:00.000000',
          }
        ]
      };
      expect(serialized, serializedExpected);

      // Test deserialization from encodable object
      final deserialized = jsonSerializers.deserialize(serializedExpected);
      expect(deserialized, videos);

      // Test encoding to a string
      final encoded = json.encode(serialized);
      final encodedExpected =
          r'{"$":"list","":[{"$":"Video","title":"Test Title 1","description":"Description 1","sourceUrl":"https://www.example.com/1","sourceReleaseDate":"1970-01-01T00:00:00.000Z","creators":["Mike Miller"],"duration":"0:01:00.000000"},{"$":"Video","title":"Test Title 2","description":"Description 2","sourceUrl":"https://www.example.com/2","sourceReleaseDate":"1970-01-01T00:00:00.000Z","creators":["Mike Miller"],"duration":"0:02:00.000000"}]}';
      expect(encoded, encodedExpected);

      // Test decoding from a string
      final decoded = json.decode(encodedExpected);
      expect(decoded, serialized);
      final deserializedFromDecoded = jsonSerializers.deserialize(decoded);
      expect(deserializedFromDecoded, videos);
    });
  });
}
