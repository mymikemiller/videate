import 'package:vidlib/vidlib.dart';

void main() {
  var video = Video((b) => b
    ..title = 'My Title'
    ..description = 'My Description'
    ..url = 'https://www.example.com'
    ..date = DateTime.now().toUtc());
  print('Video title: ${video.title}');
}
