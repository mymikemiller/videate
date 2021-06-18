import 'dart:async';
import 'package:vidlib/vidlib.dart';
import 'cloner_task.dart';
import 'package:meta/meta.dart';

/// Base class for downloaders, which turn [Media] on a platform into
/// [MediaFile]s that can be passed to any [Uploader]
abstract class Downloader extends ClonerTask {
  // The platform this downloader downloads from, e.g. the Youtube platform.
  Platform get platform;

  // The size of window used to ensure [Media]s come back in order.
  //
  // With a default value of 1, we essentially don't use the sliding window.
  // Individual downloaders can override this property if necessary to ensure
  // [reverseChronologicalMedia] works properly.
  int get slidingWindowSize => 1;

  Downloader();

  // Downloads the specified media.
  @nonVirtual
  Future<MediaFile> download(Media media,
      {Function(double progress) callback}) async {
    callback?.call(0);
    final mediaFile = await downloadMedia(media, callback);
    callback?.call(1);
    return mediaFile;
  }

  // Actual download logic. To be implemented by subclasses.
  @protected
  Future<MediaFile> downloadMedia(Media media,
      [Function(double progress) callback]);

  // Returns a stream containing all media in the collection. The order of
  // [Media] is not guaranteed, but because reverseChronologicalMedia uses this
  // function, [Downloader]s should aim to return them in as close to reverse
  // chronological order as possible so the slidingWindowSize can remain small.
  Stream<Media> allMedia();

  // Returns a stream that does its best to yield all media in the collection
  // in reverse order of date released (most recently released media first).
  // The [slidingWindowSize] property of this Downloader can be used to
  // increase the size of the sliding window used to better ensure order.
  Stream<Media> reverseChronologicalMedia([DateTime after]) async* {
    var slidingWindow = <Media>[];
    Media previouslyYielded;

    // Essentially this acts like "was released more recently than", 1=yes,
    // -1=no, 0=same
    final dateComparator = (Media a, Media b) {
      // Sort first on releaseDate...
      var cmp = a.source.releaseDate.compareTo(b.source.releaseDate);
      if (cmp == 0) {
        // When dates match, secondarily sort by title
        return a.title.compareTo(b.title);
      }
      return cmp;
    };

    // Do the best to ensure the media are returned in the order expected
    await for (var media in allMedia()) {
      // We want the media in slidingWindow to be in reverse date order
      // (slidingWindow[0] should be the most recent media). As an example of
      // why the slidingWindow is necesary, media generally are returned by the
      // YouTube API in this order (and assumably ALWAYS in this order by
      // YoutubeExplode), but often media may come back slightly out of order
      // (with the Youtube API they're returned in upload order not publish
      // order), so find the first media in the window that has a date older
      // than this media and add this media right before it (otherwise add this
      // media at the end if we don't find any out of order media)
      var i = 0;
      while (i < slidingWindow.length &&
          dateComparator(media, slidingWindow[i]) < 0) {
        i++;
      }

      slidingWindow.insert(i, media);

      if (slidingWindow.length > slidingWindowSize) {
        // Yield the most recent media from the sliding window
        final toYield = slidingWindow.removeAt(0);

        // Early-out if we're about to yield media that's not after the
        // specified date. Because slidingWindow is ordered, no remaining media
        // will be after the date.
        if (after != null && !toYield.source.releaseDate.isAfter(after)) {
          return;
        }

        // Assert that we're always yielding in reverse date order. If we ever
        // fail this assertion, slidingWindowSize may need to be increased for
        // this [Downloader].
        if (previouslyYielded != null) {
          assert(dateComparator(previouslyYielded, toYield) >= 0);
        }
        previouslyYielded = toYield;
        yield toYield;
      }
    }

    // Yield the remaining items in the window
    for (var media in slidingWindow) {
      // Early-out if we're about to yield media that's not after the
      // specified date. Because slidingWindow is ordered, no remaining media
      // will be after the date.
      if (after != null && !media.source.releaseDate.isAfter(after)) {
        return;
      }

      if (previouslyYielded != null) {
        // Assert that we're always yielding in reverse date order. If not,
        // slidingWindowSize may need to be increased for this [Downloader]
        assert(dateComparator(media, previouslyYielded) <= 0);
      }
      previouslyYielded = media;
      yield media;
    }
  }

  // Returns the most recently released media in the collection.
  Future<Media> mostRecentMedia() async {
    return reverseChronologicalMedia().first;
  }

  // Returns a string that is guaranteed to be unique among all media sourced
  // from the cloner's platform
  String getSourceUniqueId(Media media);

  // Creates a feed with no media, but with all the basic information, such as
  // author, from the specified source collection.
  Future<Feed> createEmptyFeed();
}
