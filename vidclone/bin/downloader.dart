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
  // [Videos] is not guaranteed, but because allVideosInOrder uses this
  // function, [Downloader]s should aim to return them in as close to reverse
  // chronological order as possible so the slidingWindowSize can remain small.
  Stream<Video> allVideos(SourceCollection sourceCollection);

  // Returns a stream that does its best to yield all videos in the collection
  // in reverse order of date released (most recently released video first).
  // The [slidingWindowSize] property of this Downloader can be used to
  // increase the size of the sliding window used to better ensure order.
  Stream<Video> reverseChronologicalVideos(SourceCollection sourceCollection,
      [DateTime after]) async* {
    var slidingWindow = <Video>[];
    Video previouslyYielded;

    // Essentially this acts like "is after", 1=yes, -1=no, 0=same
    final dateComparator = (Video a, Video b) {
      // Sort first on releaseDate...
      var cmp = a.source.releaseDate.compareTo(b.source.releaseDate);
      if (cmp == 0) {
        // When dates match, secondarily sort by uri path
        return a.source.uri.path.compareTo(b.source.uri.path);
      }
      return cmp;
    };

    // Do the best to ensure the videos are returned in the order expected
    await for (var video in allVideos(sourceCollection)) {
      // We want the videos in slidingWindow to be in reverse date order. As an
      // example of why the slidingWindow is necesary, videos generally are
      // returned by the YouTube API in this order (and assumably ALWAYS in
      // this order by YoutubeExplode), but often videos may come back slightly
      // out of order (with the Youtube API they're returned in upload order
      // not publish order), so find the first video in the window that has a
      // date older than this video and add this video right before it
      // (otherwise add this video at the end if we don't find any out of order
      // videos)
      var i = 0;
      while (i < slidingWindow.length &&
          dateComparator(video, slidingWindow[i]) < 0) {
        i++;
      }

      slidingWindow.insert(i, video);

      if (slidingWindow.length > slidingWindowSize) {
        // Yield the most recent video from the sliding window
        final toYield = slidingWindow.removeAt(0);

        // Early-out if we're about to yield a video that's not after the
        // specified date. Because slidingWindow is ordered, no remaining videos
        // will be after the date.
        if (after != null && !toYield.source.releaseDate.isAfter(after)) {
          return;
        }

        // Assert that we're always yielding in reverse date order. If we ever
        // fail this assertion, slidingWindowSize may need to be increased for
        // this [Downloader]
        if (previouslyYielded != null) {
          assert(dateComparator(previouslyYielded, toYield) > 0);
        }
        previouslyYielded = toYield;
        yield toYield;
      }
    }

    // Yield the remaining items in the window
    for (var video in slidingWindow) {
      // Early-out if we're about to yield a video that's not after the
      // specified date. Because slidingWindow is ordered, no remaining videos
      // will be after the date.
      if (after != null && !video.source.releaseDate.isAfter(after)) {
        return;
      }

      if (previouslyYielded != null) {
        // Assert that we're always yielding in reverse date order. If not,
        // slidingWindowSize may need to be increased for this [Downloader]
        assert(dateComparator(video, previouslyYielded) <= 0);
      }
      previouslyYielded = video;
      yield video;
    }
  }

  // Returns the most recently released video in the collection.
  Future<Video> mostRecentVideo(SourceCollection sourceCollection) async {
    return reverseChronologicalVideos(sourceCollection).first;
  }

  // Returns a string that is guaranteed to be unique among all videos sourced
  // from the cloner's platform
  String getSourceUniqueId(Video video);

  // Perform any cleanup. This downloader should no longer be used after this
  // is called.
  void close();
}
