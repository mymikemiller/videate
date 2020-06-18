import 'package:vidlib/vidlib.dart';

void main() {
  var video = Video(
    (v) => v
      ..title = 'My Title'
      ..description = 'My Description'
      ..duration = Duration(minutes: 5)
      ..source = Source(
        (s) => s
          ..platform = Platform(
            (p) => p
              ..id = 'youtube'
              ..uri = Uri.parse('https://youtube.com'),
          ).toBuilder()
          ..releaseDate = DateTime.fromMillisecondsSinceEpoch(0).toUtc()
          ..id = 'qNqfYtd3HTg'
          ..uri = Uri.parse('https://www.youtube.com/watch?v=qNqfYtd3HTg'),
      ).toBuilder(),
  );

  print('Video titled ${video.title} from ${video.source.platform.id}');
}
