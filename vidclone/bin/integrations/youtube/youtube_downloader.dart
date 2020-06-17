import 'dart:io';
import 'package:file/memory.dart';
import 'package:vidlib/src/models/video.dart';
import 'dart:async';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/youtube/v3.dart' hide Video;
import 'package:vidlib/vidlib.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import '../../downloader.dart';
import '../../source_collection.dart';
import 'channel_source_collection.dart';
import 'source_collection.dart';
import 'package:path/path.dart' as p;

// We use 50, Youtube's max for this value.
final maxApiResultsPerCall = 50;

// The maximum number of videos returned by the API before yeilding the
// earliest in the window. This is necessary because videos are returned in
// upload order, not publish order. We're specifying here that we can expect
// any set of videos this size returned consecutively by the API to include the
// most recent video of any videos that have yet to be returned (in other
// words, we're expecting that creators will never upload this many videos
// before publishing an old video)
final slidingWindowSize = 99;

final memoryFileSystem = MemoryFileSystem();

class YoutubeDownloader extends Downloader {
  @override
  Platform get platform => Platform(
        (p) => p
          ..id = 'youtube'
          ..uri = Uri.parse('https://www.youtube.com'),
      );

  final YoutubeApi api;

  YoutubeDownloader._(this.api);
  factory YoutubeDownloader.fromApiKey(String apiKey) {
    final client = auth.clientViaApiKey(apiKey);
    var api = YoutubeApi(client);
    return YoutubeDownloader._(api);
  }
  factory YoutubeDownloader.fromApi(YoutubeApi api) {
    return YoutubeDownloader._(api);
  }

  @override
  String getSourceUniqueId(Video video) {
    return yt_explode.VideoId.parseVideoId(video.source.uri.toString());
  }

  @override
  Future<VideoFile> download(Video video,
      [void Function(double progress) callback]) async {
    print('Downloading `${video.title}`:');
    var yt = yt_explode.YoutubeExplode();
    final videoId =
        yt_explode.VideoId.parseVideoId(video.source.uri.toString());
    final path = p.join(memoryFileSystem.systemTempDirectory.path, videoId);
    final file = memoryFileSystem.file(path);
    await _download(videoId, yt, file, callback);
    yt.close();
    return VideoFile(video, file);
  }

  // Download the video with the specified id to the specified file, which will
  // be opened for write and when finished, closed and returned.
  Future<File> _download(String id, yt_explode.YoutubeExplode yt, File file,
      void Function(double progress) callback) async {
    // Get the video media stream.
    var manifest = await yt.videos.streamsClient.getManifest(id);

    // Get the first muxed video (the one with the lowest bitrate to save space
    // and make downloads faster for now). note that mediaStreams.muxed will
    // never be the best quality. To achieve that, we'd need to merge the audio
    // and video streams.
    var videoStreamInfo = manifest.muxed.firstWhere(
        (streamInfo) => streamInfo.container == yt_explode.Container.mp4);

    // Track the file download status.
    var len = videoStreamInfo.size.totalBytes;
    var count = 0;
    var oldProgress = -1.0;

    // Prepare the file
    var output = file.openWrite(mode: FileMode.writeOnlyAppend);

    // Listen for data received.
    var success = false;
    while (success == false) {
      try {
        await for (var data in yt.videos.streamsClient.get(videoStreamInfo)) {
          count += data.length;
          var progress = count / len;
          if (progress != oldProgress) {
            callback(progress);
            oldProgress = progress;
          }
          output.add(data);
        }
        success = true;
      } catch (e) {
        // We sometimes get the following error from the youtube_explode
        // library, which I'm not sure how to overcome so we just restart the
        // download and hope for the best the next time.
        //
        // _TypeError (type '(HttpException) => Null' is not a subtype of type
        // '(dynamic) => dynamic')
        //
        // See
        // https://stackoverflow.com/questions/62419270/re-trying-last-item-in-stream-and-continuing-from-there
        print(e);
        // Clear the file and start over
        await file.writeAsBytes([]);
        output = file.openWrite(mode: FileMode.writeOnlyAppend);
        count = 0;
        oldProgress = 1;
      }
    }
    // console.writeLine();
    print('done');
    await output.close();
    return file;
  }

  // collectionIdentifier is the channelId
  @override
  Stream<Video> allVideos(SourceCollection sourceCollection) {
    if (!(sourceCollection is YoutubeSourceCollection)) {
      throw 'sourceCollection must be a YoutubeSourceCollection';
    }
    return _allUploads(api, sourceCollection);
  }

  // Return a stream of all YouTube videos in reverse publishedAt date order
  // (most recently published video first)
  Stream<Video> _allUploads(
      YoutubeApi api, YoutubeSourceCollection sourceCollection) async* {
    if (!(sourceCollection is YoutubeChannelSourceCollection)) {
      throw 'The Youtube downloader currently only supports YoutubeChannelSourceCollection';
    }
    final channelId = sourceCollection.identifier;

    final channels =
        await api.channels.list('contentDetails, snippet', id: channelId);

    if (channels.items.isEmpty) {
      throw 'Channel not found for id ${channelId}';
    } else if (channels.items.length > 1) {
      throw 'Too many channels found for id ${channelId}';
    }

    final channel = channels.items[0];
    // final channelDescription = channel.snippet.description;
    final uploadsPlaylistId = channel.contentDetails.relatedPlaylists.uploads;
    // '' means we're requesting the first page, null means there are no more
    // pages to request
    var nextPageToken = '';
    var playlistItemsResponse;
    var slidingWindow = <Video>[];
    Video previouslyYielded;

    while (nextPageToken != null) {
      playlistItemsResponse = await api.playlistItems.list(
          'contentDetails, snippet',
          playlistId: uploadsPlaylistId,
          pageToken: nextPageToken,
          maxResults: maxApiResultsPerCall);

      nextPageToken = playlistItemsResponse.nextPageToken;

      // Add the videos in this page one by one to the sliding window, keeping
      // them in date order, picking off from the sliding window when it gets
      // too full
      for (var playlistItem in playlistItemsResponse.items) {
        final videoId = playlistItem.snippet.resourceId.videoId;
        final video = Video(
          (v) => v
            ..title = playlistItem.snippet.title
            ..description = playlistItem.snippet.description
            ..source = Source(
              (s) => s
                ..id = videoId
                ..uri = Uri.parse('https://www.youtube.com/watch?v=$videoId')
                ..platform = platform.toBuilder()
                ..releaseDate = playlistItem.snippet.publishedAt,
            ).toBuilder()
            // TODO: find correct duration. See
            // https://stackoverflow.com/questions/15596753/how-do-i-get-video-durations-with-youtube-api-version-3
            // and https://issuetracker.google.com/issues/35170788#comment10
            ..duration = Duration(hours: 0, minutes: 15, seconds: 0),
        );

        // We want the videos in slidingWindow to be in reverse date order (they
        // generally are returned by the YouTube API in this order, but often
        // videos come back slightly out of order likely because they're returned
        // in upload order not publish order), so find the first video that has a
        // date older than this video and add this video right before it
        // (otherwise add this video at the end if we don't find any out of order
        // videos)
        var i;
        for (i = 0; i < slidingWindow.length; i++) {
          if (video.source.releaseDate
                  .compareTo(slidingWindow[i].source.releaseDate) >
              0) {
            break;
          }
        }

        slidingWindow.insert(i, video);

        if (slidingWindow.length > slidingWindowSize) {
          // Yield the most recent video in the sliding window
          final toYield = slidingWindow.removeAt(0);
          // Assert that we're always yielding in reverse date order
          assert(previouslyYielded == null ||
              previouslyYielded.source.releaseDate
                      .compareTo(toYield.source.releaseDate) >
                  0);
          previouslyYielded = toYield;
          yield toYield;
        }
      }
    }

    // Yield the remaining items in the window
    for (var video in slidingWindow) {
      // Guarantee that we're return videos in publish order, not upload order.
      // If this ever fails, slidingWindowSize may need to be increased.
      assert(previouslyYielded == null ||
          previouslyYielded.source.releaseDate
                  .compareTo(video.source.releaseDate) >
              0);
      previouslyYielded = video;
      yield video;
    }
  }
}
