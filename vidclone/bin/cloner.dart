import 'dart:io';
import 'package:vidlib/vidlib.dart';
import 'package:file/memory.dart';
import 'downloader.dart';
import 'feed_manager.dart';
import 'source_collection.dart';
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

  Future<ServedVideo> clone(Video video) async {
    // We don't need to download if the eventual upload result already exists.
    final uri = _uploader.getDestinationUri(video);
    if (await _uploader.existsAtDestination(video)) {
      throw 'Upload result $uri already exists. Use CloneIfNecessary or check '
          'uploader.existsAtDestination before calling clone';
    }

    final videoDebugName =
        '${video.source.platform.id} Video ${video.source.id}';

    Console.init();
    var progressBar = ProgressBar();

    // Download
    print('=== Clone: Download $videoDebugName ===');
    final fsVideo = await _downloader.download(video, (double progress) {
      updateProgressBar(progressBar, progress);
    });

    // Upload
    print('=== Clone: Upload $videoDebugName ===');
    final servedVideo = await _uploader.upload(fsVideo);

    print('served video: ${servedVideo.uri}');

    // Update the feed to include the new video
    print('=== Clone: Add $videoDebugName to Feed ===');
    await _feedManager.add(servedVideo);

    print('=== Clone: Finished Cloning $videoDebugName ===');

    return servedVideo;
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

  // Clones the specified video and returns the resulting ServedVideo, or null
  // if the video has already been cloned.
  //
  // Ideally we would be able to create a ServedVideo referencing the
  // already-cloned video, but that would require knowing all the information
  // required to construct a Video (title, description, etc)
  Future<ServedVideo> cloneIfNecessary(Video video) async {
    if (await _uploader.existsAtDestination(video)) {
      final uri = _uploader.getDestinationUri(video);
      print('Skipping "${video.title}" because it already exists at '
          'destination: $uri');
      return null;
    } else {
      return clone(video);
    }
  }

  // Downloads and subsequently uploads the collection's most recent video.
  //
  // Downloading and uploading will be performed according to this Cloner's
  // Downloader and Upoader behavior. Videos will be downloaded in the order
  // returned by the Downloader's videosAfter stream, and uploaded as soon as
  // the download is complete.
  Future<ServedVideo> cloneMostRecentVideo(
      SourceCollection sourceCollection) async {
    final video = await _downloader.mostRecentVideo(sourceCollection);
    final servedVideo = await cloneIfNecessary(video);
    return servedVideo;
  }

  // Downloads and subsequently uploads all videos published after the
  // specified date.
  //
  // Downloading and uploading will be performed according to this Cloner's
  // Downloader and Upoader behavior. Videos will be downloaded in the order
  // returned by the Downloader's videosAfter stream, and uploaded as soon as
  // the download is complete before moving on to the next video in the Stream.
  //
  // This function can be parallelized, but caution should be taken to ensure
  // upload order is maintained if desired, and blocking doesn't occur due to
  // too many simultaneous downloads/uploads.
  Stream<ServedVideo> cloneVideosAfter(
      DateTime date, SourceCollection sourceCollection) async* {
    // Because videosAfter returns newest videos first, we must first get the
    // list of all videos and reverse it before cloning any videos.
    var stream = _downloader.videosAfter(date, sourceCollection);
    final videos = await stream.toList();
    if (videos.isEmpty) {
      print('No videos found after $date for ${sourceCollection}');
    } else {
      for (var video in videos.reversed) {
        // This can be parallelized, but for simplicity's sake we're awaiting
        // each one here
        // TODO: parallelize this (a queue allowing up to x downloads to run at
        // once). See https://pub.dev/packages/queue
        final servedVideo = await cloneIfNecessary(video);
        yield servedVideo;
      }
    }
  }
}
