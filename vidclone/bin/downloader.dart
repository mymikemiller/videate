import 'dart:async';
import 'package:vidlib/vidlib.dart';
import 'source_collection.dart';

/// Base class for downloaders, which turn [Video]s on a platform into
/// [VideoFile]s that can be passed to any [Uploader]
abstract class Downloader {
  // The platform this downloader downloads from, e.g. the Youtube platform.
  Platform get platform;

  // final int slidingWindowSize;

  // The size of window used to ensure [Video]s come back in order.
  //
  // With a default value of 1, we essentially don't use the sliding window.
  // Individual downloaders can override this property if necessary to ensure
  // [allVideosInOrder] works properly.
  int get slidingWindowSize => 1;

  Downloader();

  // Downloads the specified video.
  Future<VideoFile> download(Video video,
      [void Function(double progress) callback]);

  // Returns a stream containing all videos in the collection. The order of
  // [Videos] is not guaranteed, but returning them in
  Stream<Video> allVideos(SourceCollection sourceCollection);

  // Returns a stream that does its best to yield all videos in the collection
  // in reverse order of date released (most recently released video first).
  // The [slidingWindowSize] property of this Downloader can be used to
  // increase the size of the sliding window used to ensure order.
  Stream<Video> allVideosInOrder(SourceCollection sourceCollection) async* {
    var slidingWindow = <Video>[];
    Video previouslyYielded;

    final isBefore = (Video a, Video b) {
      var cmp = a.source.releaseDate.compareTo(b.source.releaseDate);
      if (cmp == 0) {
        // When dates match, secondarily yield in order of uri path
        return a.source.uri.path.compareTo(b.source.uri.path) < 0;
      }

      return cmp < 0;
    };

    // Do the best to ensure the videos are returned in order of date released
    await for (var video in allVideos(sourceCollection)) {
      // We want the videos in slidingWindow to be in reverse date order (they
      // generally are returned by the YouTube API in this order, but often
      // videos may come back slightly out of order like what happens when
      // using the youtube API (they're returned in upload order not publish
      // order), so find the first video that has a date older than this video
      // and add this video right before it (otherwise add this video at the
      // end if we don't find any out of order videos)
      var i;
      for (i = 0; i < slidingWindow.length; i++) {
        if (isBefore(video, slidingWindow[i])) break;
      }

      slidingWindow.insert(i, video);

      if (slidingWindow.length > slidingWindowSize) {
        // Yield the most recent video from the sliding window
        final toYield = slidingWindow.removeAt(0);
        // Assert that we're always yielding in reverse date order. If not,
        // slidingWindowSize may need to be increased for this [Downloader]
        if (previouslyYielded != null) {
          assert(isBefore(previouslyYielded, toYield));
        }
        previouslyYielded = toYield;
        yield toYield;
      }
    }

    // Yield the remaining items in the window
    for (var video in slidingWindow) {
      if (previouslyYielded != null) {
        assert(isBefore(previouslyYielded, video));
      }
      previouslyYielded = video;
      yield video;
    }
  }

  // Returns the most recently released video in the collection.
  Future<Video> mostRecentVideo(SourceCollection sourceCollection) async {
    return allVideosInOrder(sourceCollection).first;
  }

  // Returns a stream containing all videos in the collection that were
  // published after the specified date (non-inclusive) in reverse date order
  // (most recently released video first)
  Stream<Video> videosAfter(
      DateTime date, SourceCollection sourceCollection) async* {
    await for (var video in allVideosInOrder(sourceCollection)) {
      // Stop at the first video that is too old
      if (!video.source.releaseDate.isAfter(date)) {
        return;
      }
      yield video;
    }
  }

  // Returns a string that is guaranteed to be unique among all videos sourced
  // from the cloner's platform
  String getSourceUniqueId(Video video);

  // Perform any cleanup. This downloader should no longer be used after this
  // is called.
  void close();
}
