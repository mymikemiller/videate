import 'dart:async';
import 'dart:io';
import 'package:vidlib/vidlib.dart';
import 'source_collection.dart';

abstract class Downloader {
  // An id unique to this downloader, e.g. "youtube".
  String get id;

  // Downloads the specified video into the specified file.
  Future<VideoFile> download(Video video, {File file});

  // Returns the most recently released video in the collection.
  Future<Video> mostRecentVideo(SourceCollection sourceCollection) async {
    return allVideos(sourceCollection).first;
  }

  // Returns a stream containing all videos in the collection that were
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

  // Returns a stream containing all videos in the collection in order of date
  // released (most recently released video first).
  Stream<Video> allVideos(SourceCollection sourceCollection);

  // Returns a string that is guaranteed to be unique among all videos sourced
  // from the cloner's platform
  String getSourceUniqueId(Video video);
}
