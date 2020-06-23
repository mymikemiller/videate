import 'dart:io';
import 'package:file/memory.dart';
import 'package:vidlib/src/models/video.dart';
import 'dart:async';
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

  final yt_explode.YoutubeExplode _yt;

  YoutubeDownloader() : _yt = yt_explode.YoutubeExplode();

  @override
  String getSourceUniqueId(Video video) {
    return yt_explode.VideoId.parseVideoId(video.source.uri.toString());
  }

  @override
  Future<VideoFile> download(Video video,
      [void Function(double progress) callback]) async {
    print('Downloading `${video.title}`:');
    final videoId =
        yt_explode.VideoId.parseVideoId(video.source.uri.toString());
    final path = p.join(memoryFileSystem.systemTempDirectory.path, videoId);
    final file = memoryFileSystem.file(path);
    await _download(videoId, file, callback);
    // _yt.close();
    return VideoFile(video, file);
  }

  // Download the video with the specified id to the specified file, which will
  // be opened for write and when finished, closed and returned.
  Future<File> _download(
      String id, File file, void Function(double progress) callback) async {
    // Get the video media stream.
    // var one = await _yt.videos.streamsClient.getManifest('oufFWs7TuGI'); var
    // two = await _yt.videos.streamsClient.getManifest('YhOadP3i3a8'); var
    // three = await _yt.videos.streamsClient.getManifest('R-s-w8bXLCE');
    var manifest = await _yt.videos.streamsClient.getManifest(id);

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
        final stream = _yt.videos.streamsClient.get(videoStreamInfo);
        await for (var data in stream) {
          count += data.length;
          var progress = count / len;
          if (progress != oldProgress) {
            callback(progress);
            oldProgress = progress;
          }
          output.add(data);
          // var attempt1 =
          //     await _yt.videos.streamsClient.getManifest('YhOadP3i3a8');
        }
        success = true;
        // var attempt2 = await
        //     _yt.videos.streamsClient.getManifest('YhOadP3i3a8');
        print('success downloading ${videoStreamInfo}');
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
    print('done');
    await output.close();
    return file;
  }

  @override
  Stream<Video> allVideos(SourceCollection sourceCollection) {
    if (!(sourceCollection is YoutubeSourceCollection)) {
      throw 'sourceCollection must be a YoutubeSourceCollection';
    }
    return _allUploads(sourceCollection);
  }

  // Return a stream of all YouTube videos in reverse publishedAt date order
  // (most recently published video first)
  Stream<Video> _allUploads(YoutubeSourceCollection sourceCollection) async* {
    if (!(sourceCollection is YoutubeChannelSourceCollection)) {
      throw 'The Youtube downloader currently only supports YoutubeChannelSourceCollection';
    }
    final channelId =
        yt_explode.ChannelId.fromString(sourceCollection.identifier);
    final stream = _yt.channels.getUploads(channelId);

    await for (var upload in stream) {
      final video = Video((v) => v
        ..title = upload.title
        ..description = upload.description
        ..duration = upload.duration
        ..source = Source(
          (s) => s
            ..id = upload.id.toString()
            ..uri = Uri.parse('https://www.youtube.com/watch?v=${upload.id}')
            ..platform = platform.toBuilder()
            ..releaseDate = upload.uploadDate.toUtc(),
        ).toBuilder());

      yield video;
    }
  }

  void close() {
    _yt.close();
  }
}
