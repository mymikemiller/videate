import 'dart:convert' show json;
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';

void main() {
  group('Feed', () {
    Feed feed1;
    Feed feed2;
    BuiltList<Feed> feeds;

    setUp(() {
      feed1 = Feed((b) => b
        ..title = 'Test Feed 1'
        ..subtitle = 'Subtitle 1'
        ..description = 'Description 1'
        ..link = 'http://videate.org'
        ..author = 'Mike Miller'
        ..email = 'mike@videate.org'
        ..imageUrl = 'http://example.com/example.jpg'
        ..videos = BuiltList<ServedVideo>(
            [Examples.servedVideo1, Examples.servedVideo2]).toBuilder());

      feed2 = Feed((b) => b
        ..title = 'Test Feed 2'
        ..subtitle = 'Subtitle 2'
        ..description = 'Description 2'
        ..link = 'http://videate.org'
        ..author = 'Mike Miller'
        ..email = 'mike@videate.org'
        ..imageUrl = 'http://example.com/example.jpg'
        ..videos = BuiltList<ServedVideo>(
            [Examples.servedVideo1, Examples.servedVideo3]).toBuilder());

      feeds = BuiltList.from([feed1, feed2]);
    });

    test('constructor', () {
      expect(feed1.title, 'Test Feed 1');
      expect(feed1.subtitle, 'Subtitle 1');
      expect(feed1.description, 'Description 1');
      expect(feed1.videos, [Examples.servedVideo1, Examples.servedVideo2]);
    });

    test('JSON serialization/deserialization', () {
      final serialized = jsonSerializers.serialize(feed1);
      final serializedExpected = {
        r'$': 'Feed',
        'title': 'Test Feed 1',
        'subtitle': 'Subtitle 1',
        'description': 'Description 1',
        'link': 'http://videate.org',
        'author': 'Mike Miller',
        'email': 'mike@videate.org',
        'imageUrl': 'http://example.com/example.jpg',
        'videos': [
          {
            'video': {
              'title': 'Video 1',
              'description': 'Description 1',
              'sourceUrl': 'https://www.example.com/1',
              'sourceReleaseDate': '1970-01-01T00:00:00.000Z',
              'creators': ['Mike Miller'],
              'duration': '0:01:00.000000',
            },
            'uri': '/test/video1.mp4',
            'lengthInBytes': 100000
          },
          {
            'video': {
              'title': 'Video 2',
              'description': 'Description 2',
              'sourceUrl': 'https://www.example.com/2',
              'sourceReleaseDate': '1970-01-01T00:00:00.000Z',
              'creators': ['Mike Miller'],
              'duration': '0:02:00.000000',
            },
            'uri': '/test/video2.mp4',
            'lengthInBytes': 200000
          }
        ]
      };
      expect(serialized, serializedExpected);

      final deserialized = jsonSerializers.deserialize(serialized);
      expect(deserialized, feed1);
    });

    test('JSON serialization of lists', () {
      // Note that to support automatic deserialization of lists no matter
      // where they appear in the json, the built_value/built_collection
      // serializer puts the list inside an object under an empty string key.
      // See https://github.com/google/built_value.dart/issues/404

      // Test serialization to encodable object
      final serialized = jsonSerializers.serialize(feeds);
      final serializedExpected = {
        r'$': 'list',
        '': [
          {
            r'$': 'Feed',
            'title': 'Test Feed 1',
            'subtitle': 'Subtitle 1',
            'description': 'Description 1',
            'link': 'http://videate.org',
            'author': 'Mike Miller',
            'email': 'mike@videate.org',
            'imageUrl': 'http://example.com/example.jpg',
            'videos': [
              {
                'video': {
                  'title': 'Video 1',
                  'description': 'Description 1',
                  'sourceUrl': 'https://www.example.com/1',
                  'sourceReleaseDate': '1970-01-01T00:00:00.000Z',
                  'creators': ['Mike Miller'],
                  'duration': '0:01:00.000000',
                },
                'uri': '/test/video1.mp4',
                'lengthInBytes': 100000
              },
              {
                'video': {
                  'title': 'Video 2',
                  'description': 'Description 2',
                  'sourceUrl': 'https://www.example.com/2',
                  'sourceReleaseDate': '1970-01-01T00:00:00.000Z',
                  'creators': ['Mike Miller'],
                  'duration': '0:02:00.000000',
                },
                'uri': '/test/video2.mp4',
                'lengthInBytes': 200000
              }
            ]
          },
          {
            r'$': 'Feed',
            'title': 'Test Feed 2',
            'subtitle': 'Subtitle 2',
            'description': 'Description 2',
            'link': 'http://videate.org',
            'author': 'Mike Miller',
            'email': 'mike@videate.org',
            'imageUrl': 'http://example.com/example.jpg',
            'videos': [
              {
                'video': {
                  'title': 'Video 1',
                  'description': 'Description 1',
                  'sourceUrl': 'https://www.example.com/1',
                  'sourceReleaseDate': '1970-01-01T00:00:00.000Z',
                  'creators': ['Mike Miller'],
                  'duration': '0:01:00.000000',
                },
                'uri': '/test/video1.mp4',
                'lengthInBytes': 100000
              },
              {
                'video': {
                  'title': 'Video 3',
                  'description': 'Description 3',
                  'sourceUrl': 'https://www.example.com/2',
                  'sourceReleaseDate': '1970-01-01T00:00:00.000Z',
                  'creators': ['Mike Miller'],
                  'duration': '0:03:00.000000',
                },
                'uri': '/test/video3.mp4',
                'lengthInBytes': 300000
              }
            ]
          }
        ]
      };
      expect(serialized, serializedExpected);

      // Test deserialization from encodable object
      final deserialized = jsonSerializers.deserialize(serializedExpected);
      expect(deserialized, feeds);

      // Test encoding to a string
      final encoded = json.encode(serialized);
      final encodedExpected =
          r'{"$":"list","":[{"$":"Feed","title":"Test Feed 1","subtitle":"Subtitle 1","description":"Description 1","link":"http://videate.org","author":"Mike Miller","email":"mike@videate.org","imageUrl":"http://example.com/example.jpg","videos":[{"video":{"title":"Video 1","description":"Description 1","sourceUrl":"https://www.example.com/1","sourceReleaseDate":"1970-01-01T00:00:00.000Z","creators":["Mike Miller"],"duration":"0:01:00.000000"},"uri":"/test/video1.mp4","lengthInBytes":100000},{"video":{"title":"Video 2","description":"Description 2","sourceUrl":"https://www.example.com/2","sourceReleaseDate":"1970-01-01T00:00:00.000Z","creators":["Mike Miller"],"duration":"0:02:00.000000"},"uri":"/test/video2.mp4","lengthInBytes":200000}]},{"$":"Feed","title":"Test Feed 2","subtitle":"Subtitle 2","description":"Description 2","link":"http://videate.org","author":"Mike Miller","email":"mike@videate.org","imageUrl":"http://example.com/example.jpg","videos":[{"video":{"title":"Video 1","description":"Description 1","sourceUrl":"https://www.example.com/1","sourceReleaseDate":"1970-01-01T00:00:00.000Z","creators":["Mike Miller"],"duration":"0:01:00.000000"},"uri":"/test/video1.mp4","lengthInBytes":100000},{"video":{"title":"Video 3","description":"Description 3","sourceUrl":"https://www.example.com/2","sourceReleaseDate":"1970-01-01T00:00:00.000Z","creators":["Mike Miller"],"duration":"0:03:00.000000"},"uri":"/test/video3.mp4","lengthInBytes":300000}]}]}';
      expect(encoded, encodedExpected);

      // Test decoding from a string
      final decoded = json.decode(encodedExpected);
      expect(decoded, serialized);
      final deserializedFromDecoded = jsonSerializers.deserialize(decoded);
      expect(deserializedFromDecoded, feeds);
    });
  });
}
