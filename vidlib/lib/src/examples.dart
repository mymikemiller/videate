import 'package:vidlib/vidlib.dart';
import 'package:built_collection/built_collection.dart';

// Contains some static Media objects that can be used for testing purposes
class Examples {
  static Platform get platform => Platform(
        (p) => p
          ..id = 'example'
          ..uri = Uri.parse('https://example.com'),
      );

  static Source get source => Source((s) => s
    ..platform = platform.toBuilder()
    ..releaseDate = DateTime.fromMillisecondsSinceEpoch(0).toUtc()
    ..id = 'aaa111'
    ..uri = Uri.parse('https://www.example.com/aaa111'));

  static Media get media1 => Media(
        (v) => v
          ..title = 'Media 1'
          ..description = 'Description 1'
          ..duration = Duration(minutes: 1)
          ..source = source
              .rebuild((s) => s
                ..id = 'aaa111'
                ..uri = Uri.parse('https://www.example.com/aaa111'))
              .toBuilder(),
      );

  static Media get media2 => Media(
        (v) => v
          ..title = 'Media 2'
          ..description = 'Description 2'
          ..duration = Duration(minutes: 2)
          ..source = source
              .rebuild((s) => s
                ..id = 'bbb222'
                ..uri = Uri.parse('https://www.example.com/bbb222'))
              .toBuilder(),
      );

  static Media get media3 => Media(
        (v) => v
          ..title = 'Media 3'
          ..description = 'Description 3'
          ..duration = Duration(minutes: 3)
          ..source = source
              .rebuild((s) => s
                ..id = 'ccc333'
                ..uri = Uri.parse('https://www.example.com/ccc333'))
              .toBuilder(),
      );

  static ServedMedia get servedMedia1 => ServedMedia((b) => b
    ..uri = Uri(path: '/test/video1.mp4')
    ..media = media1.toBuilder()
    ..etag = 'abc111xyz'
    ..lengthInBytes = 100000);
  static ServedMedia get servedMedia2 => ServedMedia((b) => b
    ..uri = Uri(path: '/test/video2.mp4')
    ..media = media2.toBuilder()
    ..etag = 'abc222xyz'
    ..lengthInBytes = 200000);
  static ServedMedia get servedMedia3 => ServedMedia((b) => b
    ..uri = Uri(path: '/test/video3.mp4')
    ..media = media3.toBuilder()
    ..etag = 'abc333xyz'
    ..lengthInBytes = 300000);

  static Feed get emptyFeed => Feed((b) => b
    ..title = 'Title'
    ..subtitle = 'Subtitle'
    ..description = 'Description'
    ..link = 'http://www.videate.org'
    ..author = 'Mike Miller'
    ..email = 'mike@videate.org'
    ..imageUrl =
        'https://media.istockphoto.com/vectors/folder-icon-with-a-rss-feed-sign-vector-id483567250'
    ..mediaList = BuiltList<ServedMedia>([]).toBuilder());

  static Feed get feed1 => Feed((b) => b
    ..title = 'Test Feed 1'
    ..subtitle = 'Subtitle 1'
    ..description = 'Description 1'
    ..link = 'http://videate.org'
    ..author = 'Mike Miller'
    ..email = 'mike@videate.org'
    ..imageUrl = 'http://example.com/example.jpg'
    ..mediaList =
        BuiltList<ServedMedia>([servedMedia1, servedMedia2]).toBuilder());

  static Feed get feed2 => Feed((b) => b
    ..title = 'Test Feed 2'
    ..subtitle = 'Subtitle 2'
    ..description = 'Description 2'
    ..link = 'http://videate.org'
    ..author = 'Mike Miller'
    ..email = 'mike@videate.org'
    ..imageUrl = 'http://example.com/example.jpg'
    ..mediaList =
        BuiltList<ServedMedia>([servedMedia1, servedMedia3]).toBuilder());
}
