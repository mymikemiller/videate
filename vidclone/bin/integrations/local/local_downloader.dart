import 'package:vidlib/src/models/video_file.dart';
import 'package:vidlib/src/models/video.dart';
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/vidlib.dart';
import 'dart:io';
import '../../downloader.dart';
import 'package:path/path.dart';
import '../../source_collection.dart';
import 'local_source_collection.dart';

// Doesn't actually download anything, instead constructs Video objects based on files in a folder.
class LocalDownloader extends Downloader {
  @override
  String get id => 'local';

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
    // top of the list. Secondarily sort by path for consistency when dates match.
    files.sort((FileSystemEntity a, FileSystemEntity b) {
      var cmp = b.statSync().modified.compareTo(a.statSync().modified);
      if (cmp != 0) return cmp;
      return b.path.compareTo(a.path);
    });

    for (var file in files) {
      // Only serve video files
      if (isVideo(file)) {
        final duration = await getDuration(file, processRunner: ffprobeRunner);

        final video = Video((b) => b
          ..title = basename(file.path)
          ..description = basenameWithoutExtension(file.path)
          ..sourceUrl = file.path
          // We don't know the source release date, so we set it to epoch.
          // Setting it to the file's modified date
          // (file.statSync().modified.toUtc()) would ensure the videos show up
          // in a somewhat desirable order, but this causes issues with testing
          // because the test files end up with different modified dates on the
          // CI server.
          ..sourceReleaseDate = DateTime.fromMillisecondsSinceEpoch(0).toUtc()
          ..creators = BuiltList<String>(['Mike Miller']).toBuilder()
          ..duration = duration);

        yield video;
      }
    }
  }

  @override
  Future<VideoFile> download(Video video, {File file}) {
    if (file != null) {
      throw 'LocalFolderDownloader::download must not be passed a File to download into. The existing File in the local folder will be used.';
    }
    final localFile = File(video.sourceUrl);
    final videoFile = VideoFile(video, localFile);
    return Future.value(videoFile);
  }

  @override
  String getSourceUniqueId(Video video) {
    return video.sourceUrl;
  }
}
