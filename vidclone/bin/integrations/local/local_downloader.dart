import 'package:vidlib/src/models/video_file.dart';
import 'package:vidlib/src/models/video.dart';
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/vidlib.dart';
import 'dart:io';
import '../../downloader.dart';
import 'package:path/path.dart';
import '../../source_collection.dart';
import 'local_source_collection.dart';

// Doesn't actually download anything, instead constructs Video objects based
// on files in a folder.
class LocalDownloader extends Downloader {
  @override
  Platform get platform => Platform(
        (p) => p
          ..id = 'local'
          ..uri = Uri(path: '/'),
      );

  final dynamic ffprobeRunner;

  LocalDownloader({this.ffprobeRunner = Process.run});

  // collectionIdentifier is unused for this Downloader
  @override
  Stream<Video> allVideos(SourceCollection sourceCollection) async* {
    if (!(sourceCollection is LocalSourceCollection)) {
      throw 'sourceCollection must be a LocalSourceCollection';
    }
    final files =
        Directory(sourceCollection.identifier).listSync(recursive: false);

    // Order by date modified so if new videos are added, they'll appear at the
    // top of the list. Secondarily sort by path for consistency when dates
    // match.
    files.sort((FileSystemEntity a, FileSystemEntity b) {
      // Note: We tried sorting first by date modified and secondarily by path,
      // but this caused files to be returned in different order on different
      // machines even if all the files in the folder were the same (e.g. on
      // the CI server, where the modified date doesn't match that of the
      // original file). So instead we use sort by path, which should be a
      // consistent order across machines, even if the absolute paths differ
      // since everything shoudld be in the same folder. Uncomment the below
      // lines to add back in the sort-by-date-then-by-path logic.
      //
      // var cmp = b.statSync().modified.compareTo(a.statSync().modified); if
      // (cmp != 0) return cmp;
      return b.path.compareTo(a.path);
    });

    for (var file in files) {
      // Only 'download' video files
      if (isVideo(file)) {
        final duration = await getDuration(file, processRunner: ffprobeRunner);

        final video = Video(
          (b) => b
            ..title = basenameWithoutExtension(file.path)
            ..description = basename(file.path)
            ..source = Source(
              (s) => s
                // Assume filenames will be unique among all local files.
                // Obviously a faulty assumption as this could cause collisions
                // when this id is used during upload, but the simplicity is
                // worth the tradeoff for the places we make use of
                // LocalDownloader.
                ..id = basenameWithoutExtension(file.path)
                // We don't know the source release date, so we set it to
                // epoch. Setting it to the file's modified date
                // (file.statSync().modified.toUtc()) would ensure the videos
                // show up in a somewhat desirable order, but this causes
                // issues with testing because the test files end up with
                // different modified dates on the CI server.
                ..releaseDate = DateTime.fromMillisecondsSinceEpoch(0).toUtc()
                ..uri = Uri.file(file.path)
                ..platform = platform.toBuilder(),
            ).toBuilder()
            ..creators = BuiltList<String>(['Mike Miller']).toBuilder()
            ..duration = duration,
        );

        yield video;
      }
    }
  }

  /// Downloads the specified [Video].
  @override
  Future<VideoFile> download(Video video,
      [void Function(double progress) callback]) {
    final sourceFile = File(video.source.uri.toString());
    final videoFile = VideoFile(video, sourceFile);
    return Future.value(videoFile);
  }

  @override
  String getSourceUniqueId(Video video) {
    return video.source.uri.toString();
  }

  @override
  void close() {
    // do nothing
  }
}
