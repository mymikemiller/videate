import 'dart:async';
import 'dart:io';
import 'package:vidlib/vidlib.dart';
import 'source_collection.dart';

abstract class Downloader {
  // An id unique to this downloader, e.g. "youtube".
  String get id;

  // Download the specified video into the specified file.
  Future<VideoFile> download(Video video, {File file});

  // Return a stream containing all videos in the collection that were
  // published after the specified date (non-inclusive).
  Future<Video> mostRecentVideo(SourceCollection sourceCollection) async {
    return allVideos(sourceCollection).first;
  }

  // Return a stream containing all videos in the collection that were
  // published after the specified date (non-inclusive).
  Stream<Video> videosAfter(
      DateTime date, SourceCollection sourceCollection) async* {
    await for (var video in allVideos(sourceCollection)) {
      // Stop at the first video that is too old
      if (!video.sourceReleaseDate.isAfter(date)) {
        return;
      }
      yield video;
    }
  }

  // Return a stream containing all videos in the collection in order of date
  // published (most recently published video first).
  Stream<Video> allVideos(SourceCollection sourceCollection);

  // Returns a string that is guaranteed to be unique among all videos sourced
  // from the cloner's platform
  String getSourceUniqueId(Video video);
}
