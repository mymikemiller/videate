import 'package:vidlib/vidlib.dart';
import 'package:file/memory.dart';
import 'downloader.dart';
import 'feed_manager.dart';
import 'source_collection.dart';
import 'uploader.dart';

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

    // Download
    print('=== Clone: Download $videoDebugName } ===');
    final fsVideo = await _downloader.download(video);

    // Upload
    print('=== Clone: Upload $videoDebugName ===');
    final servedVideo = await _uploader.upload(fsVideo);

    // Update the feed to include the new video
    print('=== Clone: Add $videoDebugName to Feed ===');
    await _feedManager.add(servedVideo);

    print('=== Clone: Finished Cloning $videoDebugName ===');

    return servedVideo;
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
    final stream = _downloader.videosAfter(date, sourceCollection);
    if (await stream.isEmpty) {
      print('No videos found after $date for '
          '${sourceCollection.platform.id} '
          '${sourceCollection.identifierMeaning} '
          '${sourceCollection.identifier}');
    } else {
      await for (var video in stream) {
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
