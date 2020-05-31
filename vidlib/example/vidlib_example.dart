import 'package:vidlib/vidlib.dart';

void main() {
  var video = Video((b) => b
    ..title = 'My Title'
    ..description = 'My Description'
    ..sourceUrl = 'https://www.example.com'
    ..sourceReleaseDate = DateTime.now().toUtc());
  print('Video title: ${video.title}');
}
