import 'dart:io';
import 'package:file/local.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';

void main() {
  group('VideoUtilities', () {
    test('parses duration', () async {
      expect(
          parseDuration('11:22:33.456789'),
          Duration(
              hours: 11,
              minutes: 22,
              seconds: 33,
              milliseconds: 456,
              microseconds: 789));
    });
    test('gets mocked video duration', () async {
      // The test container won't have ffprobe installed, so we stub the
      // results
      final ffprobeStub = (String executable, List<String> arguments) =>
          ProcessResult(0, 0, '0:00:06.038000', '');
      final videoFile =
          LocalFileSystem().file('test/resources/six_second_video.mp4');
      final duration = await getDuration(videoFile, processRunner: ffprobeStub);
      expect(duration,
          Duration(hours: 0, minutes: 0, seconds: 6, milliseconds: 38));
    });
  });
}
