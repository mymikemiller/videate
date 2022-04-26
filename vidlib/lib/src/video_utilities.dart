// Helper functions to get information about a video
import 'dart:convert';
import 'dart:io' as io;
import 'package:path/path.dart';
import 'package:file/local.dart';
import 'package:file/file.dart';
import 'package:mime/mime.dart';
import 'package:vidlib/vidlib.dart';

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

bool isVideo(File file) {
  return lookupMimeType(file.path)?.startsWith('video') ?? false;
}

// Gets the duration of the specified video. Specify a mock processRunner for
// testing on machines that may not have ffprobe installed.
Future<Duration> getDuration(File videoFile,
    {processRunner = io.Process.run}) async {
  if (!isVideo(videoFile)) {
    throw ArgumentError(
        'Cannot get duration of non-video file ${videoFile.path}');
  }
  final args = [
    '-v',
    'error',
    '-show_entries',
    'format=duration',
    '-of',
    'default=noprint_wrappers=1:nokey=1',
    '-sexagesimal',
    videoFile.path
  ];
  // final command = 'ffprobe ${args.join(' ')}';
  final output = await processRunner('ffprobe', args);

  if (output.stderr.isNotEmpty) {
    throw 'ffprobe error: ${output.stderr}';
  }

  final duration = parseDuration(output.stdout);
  return duration;
}

// Converts a video file to one of lower quality/filesize. Specify a mock
// processStarter for testing on machines that may not have ffprobe installed.
class FfmpegVideoConverter extends Converter<File, Future<File>> {
  final processStarter;
  const FfmpegVideoConverter({this.processStarter = io.Process.start});

  // Default for crf (Constant Rate Factor) is 28 for x265; higher numbers
  // result in lower quality and lower file sizes
  @override
  Future<File> convert(File input,
      {String? vcodec,
      int? height,
      int crf = 28,
      Function(double progress)? callback}) async {
    if (!isVideo(input)) {
      throw 'input must be a File object representing a video file';
    }

    // ffmpeg can only work on local files
    final localFile = await ensureLocal(input);

    final localFilePath = localFile.path;
    final tempDir = createTempDirectory(LocalFileSystem());
    // TODO: don't assume mp4 extension
    final outputPath =
        '${tempDir.path}/${basenameWithoutExtension(localFilePath)}.mp4';

    var totalDuration;
    final args = [
      '-i',
      '$localFilePath',
      '-vf',
      // Specify the width/height of the resulting video. A negative value for
      // width tells ffmpeg to use an appropriate width that preserves the
      // aspect ratio. We use '-2' because the libx265 encoder requires the
      // width to be a multiple of 2.
      'scale=-2:$height',
      '-vcodec',
      '$vcodec', // mpeg4, libx264, libx265
      '-q:v',
      '3',
      '-crf',
      '$crf',
      '-movflags',
      '+faststart',
      '$outputPath',
    ];
    // final command = args.join(' ');

    // ffmpeg -i "input.mp4" -vf scale=-2:540 -vcodec libx264 -q:v 3 -crf 28 -movflags +faststart "output.mp4"
    await processStarter('ffmpeg', args).then((p) async {
      p.stderr.transform(Utf8Decoder()).listen((String data) {
        final timeFormat = r'\d{2}:\d{2}:\d{2}\.\d{2}';
        if (totalDuration == null) {
          // The video's duration is specified in an early print to stderr:
          // Duration: 00:04:44.12
          final durationRegex = RegExp('Duration: ($timeFormat)');
          final durationMatches = durationRegex.allMatches(data);
          if (durationMatches.isNotEmpty) {
            totalDuration = parseDuration(durationMatches.last.group(1)!);
          }
        }

        // ffmpeg conversion outputs many lines to stderr (even though they're
        // not errors) which look like the following:
        //
        // frame= 6648 fps=245 q=35.7 size=    6144kB time=00:03:41.75 bitrate=
        // 227.0kbits/s speed=8.16x
        //
        // We're interested in the 'time' value so we can compute our progress.
        final currentTimeRegex = RegExp('time=($timeFormat)');
        final currentTimeMatches = currentTimeRegex.allMatches(data);
        if (currentTimeMatches.isNotEmpty) {
          final currentTime = parseDuration(currentTimeMatches.last.group(1)!);
          final progress =
              currentTime.inMilliseconds / totalDuration.inMilliseconds;
          callback?.call(progress);
        }
      });

      final exitCode = await p.exitCode;
      if (exitCode != 0) {
        throw 'ffmpeg convert error (exitCode $exitCode)';
      }
    });

    final outputFile = LocalFileSystem().file(outputPath);
    return outputFile;
  }
}
