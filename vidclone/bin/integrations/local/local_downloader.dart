import 'package:file/local.dart';
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/vidlib.dart';
import 'dart:io';
import '../../downloader.dart';
import 'package:path/path.dart';

// Doesn't actually download anything, instead constructs Media objects based
// on files in a folder.
class LocalDownloader extends Downloader {
  Directory sourceDirectory;

  static Platform getPlatform() => Platform(
        (p) => p
          ..id = 'local'
          ..uri = Uri(path: '/'),
      );

  @override
  Platform get platform => getPlatform();

  @override
  void configure(ClonerTaskArgs downloaderArgs) {
    super.configure(downloaderArgs);
    final path = downloaderArgs.get('path');
    sourceDirectory = LocalFileSystem().directory(path);
  }

  // An arbitrarily large slidingWindowSize will ensure we return [Media]s in a
  // predictable order
  @override
  int get slidingWindowSize => 99999;

  final dynamic ffprobeRunner;

  LocalDownloader({this.ffprobeRunner = Process.run}) : super();

  // collectionIdentifier is unused for this Downloader
  @override
  Stream<Media> allMedia() async* {
    final files =
        sourceDirectory.listSync(recursive: false).whereType<File>().toList();

    // Sort by path for consistency, since we don't know the release date for
    // local files
    files.sort((FileSystemEntity a, FileSystemEntity b) {
      // Note: We tried sorting first by date modified and secondarily by path,
      // but this caused files to be returned in different order on different
      // machines even if all the files in the folder were the same (e.g. on the
      // CI server, where the modified date doesn't match that of the original
      // file). So instead we sort by path, which will be a consistent order
      // across machines, even if the absolute paths differ since everything
      // should be in the same folder. Uncomment the below lines to add back in
      // the sort-by-date-then-by-path logic.
      //
      // var cmp = b.statSync().modified.compareTo(a.statSync().modified); if
      // (cmp != 0) return cmp;
      return a.path.compareTo(b.path);
    });

    for (var file in files) {
      // Only 'download' video files for now
      if (isVideo(file)) {
        final duration = await getDuration(file, processRunner: ffprobeRunner);

        final media = Media(
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
                // (file.statSync().modified.toUtc()) would ensure the media
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

        yield media;
      }
    }
  }

  /// "Downloads" the specified [Media] by simply creating a [MediaFile] from
  /// the [File] at the [Media]'s uri
  @override
  Future<MediaFile> downloadMedia(Media media,
      [Function(double progress) callback]) {
    callback?.call(0);
    final path = Uri.decodeFull(media.source.uri.path.toString());
    final sourceFile = LocalFileSystem().file(path);
    if (!sourceFile.existsSync()) {
      throw 'Could not download local file. File not found: $path';
    }
    final mediaFile = MediaFile(media, sourceFile);
    callback?.call(1);
    return Future.value(mediaFile);
  }

  @override
  String getSourceUniqueId(Media media) {
    return media.source.uri.toString();
  }

  @override
  Future<Feed> createEmptyFeed() {
    return Future.value(Examples.emptyFeed.rebuild((b) {
      // Name the feed the same as the folder's name
      final feedName = basename(sourceDirectory.path);
      return b
        ..title = feedName
        ..subtitle = '$feedName feed';
    }));
  }
}
