import 'package:vidlib/vidlib.dart';
import 'package:built_collection/built_collection.dart';

// Contains some static Video objects that can be used for testing purposes
class Examples {
  static Video get video1 => Video((b) => b
    ..title = 'Video 1'
    ..description = 'Description 1'
    ..sourceUrl = 'https://www.example.com/1'
    ..sourceReleaseDate = DateTime.fromMillisecondsSinceEpoch(0).toUtc()
    ..creators = BuiltList<String>(['Mike Miller']).toBuilder()
    ..duration = Duration(minutes: 1));
  static Video get video2 => Video((b) => b
    ..title = 'Video 2'
    ..description = 'Description 2'
    ..sourceUrl = 'https://www.example.com/2'
    ..sourceReleaseDate = DateTime.fromMillisecondsSinceEpoch(0).toUtc()
    ..creators = BuiltList<String>(['Mike Miller']).toBuilder()
    ..duration = Duration(minutes: 2));
  static Video get video3 => Video((b) => b
    ..title = 'Video 3'
    ..description = 'Description 3'
    ..sourceUrl = 'https://www.example.com/2'
    ..sourceReleaseDate = DateTime.fromMillisecondsSinceEpoch(0).toUtc()
    ..creators = BuiltList<String>(['Mike Miller']).toBuilder()
    ..duration = Duration(minutes: 3));

  static ServedVideo get servedVideo1 => ServedVideo((b) => b
    ..uri = Uri(path: '/test/video1.mp4')
    ..video = video1.toBuilder()
    ..lengthInBytes = 100000);
  static ServedVideo get servedVideo2 => ServedVideo((b) => b
    ..uri = Uri(path: '/test/video2.mp4')
    ..video = video2.toBuilder()
    ..lengthInBytes = 200000);
  static ServedVideo get servedVideo3 => ServedVideo((b) => b
    ..uri = Uri(path: '/test/video3.mp4')
    ..video = video3.toBuilder()
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
    ..videos = BuiltList<ServedVideo>([]).toBuilder());

  static Feed get feed1 => Feed((b) => b
    ..title = 'Test Feed 1'
    ..subtitle = 'Subtitle 1'
    ..description = 'Description 1'
    ..link = 'http://videate.org'
    ..author = 'Mike Miller'
    ..email = 'mike@videate.org'
    ..imageUrl = 'http://example.com/example.jpg'
    ..videos =
        BuiltList<ServedVideo>([servedVideo1, servedVideo2]).toBuilder());

  static Feed get feed2 => Feed((b) => b
    ..title = 'Test Feed 2'
    ..subtitle = 'Subtitle 2'
    ..description = 'Description 2'
    ..link = 'http://videate.org'
    ..author = 'Mike Miller'
    ..email = 'mike@videate.org'
    ..imageUrl = 'http://example.com/example.jpg'
    ..videos =
        BuiltList<ServedVideo>([servedVideo1, servedVideo3]).toBuilder());
}
