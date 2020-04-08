// Helper functions to get information about a video
import 'dart:io';
import 'package:mime/mime.dart';

Duration parseDuration(String s) {
  var hours = 0;
  var minutes = 0;
  int micros;
  var parts = s.split(':');
  if (parts.length > 2) {
    hours = int.parse(parts[parts.length - 3]);
  }
  if (parts.length > 1) {
    minutes = int.parse(parts[parts.length - 2]);
  }
  micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
  return Duration(hours: hours, minutes: minutes, microseconds: micros);
}

// Gets the duration of the specified video. Specify a mock processRunner for
// testing on machines that may not have ffprobe installed.
Future<Duration> getDuration(File videoFile,
    {processRunner = Process.run}) async {
  if (!lookupMimeType(videoFile.path).startsWith('video')) {
    throw ArgumentError(
        'Cannot get duration of non-video file ${videoFile.path}');
  }
  final output = await processRunner('ffprobe', [
    '-v',
    'error',
    '-show_entries',
    'format=duration',
    '-of',
    'default=noprint_wrappers=1:nokey=1',
    '-sexagesimal',
    videoFile.path
  ]);

  final duration = parseDuration(output.stdout);
  return duration;
}
