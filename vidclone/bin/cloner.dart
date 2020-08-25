import 'dart:io';
import 'package:vidlib/vidlib.dart';
import 'package:file/memory.dart';
import 'downloader.dart';
import 'feed_manager.dart';
import 'uploader.dart';
import 'package:console/console.dart';

// A fake file system that allows us to interact with downloaded data as though
// it were a file on an actual file system, but it's only ever stored in
// memory.
final memoryFileSystem = MemoryFileSystem();

class Cloner {
  final Downloader _downloader;
  final Uploader _uploader;
  final FeedManager _feedManager;

  Cloner(this._downloader, this._uploader, this._feedManager);

  // Clones the [Video] by downloading it from the source, uploading it to the
  // destination, then updating a feed.
  //
  // Downloading and uploading will be performed according to this Cloner's
  // Downloader and Upoader behavior.
  //
  // Videos that already exist at the uploader's destination will not be
  // cloned. Instead, a [ServedVideo] will be immediately returned.
  Future<ServedVideo> clone(Video video) async {
    final videoDebugName =
        '${video.source.platform.id} Video ${video.source.id}';
    Console.init();

    // Existence Check
    print('=== Clone: Checking if already cloned: $videoDebugName ===');
    final existenceCheckResult =
        await time(_uploader.getExistingServedVideo, [video]);

    var servedVideo;

    // Short-circuit downloading and uploading if the destination exists
    if (existenceCheckResult.returnValue != null) {
      print(
          'Destination exists. Skipping Download and Upload for ${video.title}.');
      print('=== ⏲  ${existenceCheckResult.time} ⏲  ===');
      servedVideo = existenceCheckResult.returnValue;
    } else {
      print('=== ⏲  ${existenceCheckResult.time} ⏲  ===');

      // Download
      print('=== Clone: Download $videoDebugName ===');
      var progressBar = ProgressBar();
      final downloadResult = await time(_downloader.download, [
        video,
        (double progress) {
          updateProgressBar(progressBar, progress);
        }
      ]);
      final fsVideo = await downloadResult.returnValue;
      print('=== ⏲ ${downloadResult.time} ⏲ ===');

      // Upload
      print('=== Clone: Upload $videoDebugName ===');
      final uploadResult = await time(_uploader.upload, [fsVideo]);
      servedVideo = await uploadResult.returnValue;
      print('=== ⏲ ${uploadResult.time} ⏲ ===');

      print('served video: ${servedVideo.uri}');
    }

    // Update the feed to include the new video
    print('=== Clone: Add $videoDebugName to Feed ===');
    final feedAddResult = await time(_feedManager.add, [servedVideo]);
    print('=== ⏲${feedAddResult.time} ⏲ ===');

    return servedVideo;
  }

  // This function can be parallelized, but caution should be taken to ensure
  // upload order is maintained if desired, and blocking doesn't occur due to
  // too many simultaneous downloads/uploads.
  Stream<ServedVideo> _cloneAll(Iterable<Video> videos) async* {
    for (var video in videos) {
      // This can be parallelized, but for simplicity's sake we're awaiting
      // each one here TODO: parallelize this (a queue allowing up to x
      // downloads to run at once). See https://pub.dev/packages/queue
      final servedVideo = await clone(video);
      yield servedVideo;
    }
  }

  // Clones all videos published to the collection. If [after] is specified,
  // only videos published after the specified date are cloned.
  //
  // Videos will be cloned in chronological order (in the same order they were
  // originally published at the source).
  Stream<ServedVideo> cloneCollection(SourceCollection sourceCollection,
      [DateTime after]) async* {
    // Because videosAfter returns newest videos first, we must first get the
    // list of all videos and reverse it before cloning any videos.
    var stream =
        _downloader.reverseChronologicalVideos(sourceCollection, after);
    final videos = (await stream.toList()).reversed;
    if (videos.isEmpty) {
      print('No videos found after $after for ${sourceCollection}');
    } else {
      await for (var servedVideo in _cloneAll(videos)) {
        yield servedVideo;
      }
      // TODO: switch to this? yield* _cloneAll(videos);
    }
  }

  void updateProgressBar(ProgressBar progressBar, double progress) {
    final progressInt = (progress * 100).round();
    try {
      progressBar.update(progressInt);
    } on StdoutException catch (e) {
      if (e.message == 'Could not get terminal size') {
        print(
            'If using VSCode, make sure you\'re using the Integrated Terminal,'
            ' as the Debug Console does not support cursor positioning '
            'necessary to display the progress bar. Set `"console": '
            '"terminal"` in launch.json.');
      }
    }
  }

  Future<ServedVideo> cloneMostRecentVideo(
      SourceCollection sourceCollection) async {
    final video = await _downloader.mostRecentVideo(sourceCollection);
    return clone(video);
  }

  void close() {
    _downloader.close();
    _uploader.close();
    _feedManager.close();
  }
}
