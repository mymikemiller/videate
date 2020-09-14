import 'dart:io';
import 'package:file/memory.dart';
import 'package:vidlib/src/models/media.dart';
import 'dart:async';
import 'package:vidlib/vidlib.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import '../../downloader.dart';
import 'package:path/path.dart' as p;

final memoryFileSystem = MemoryFileSystem();

class YoutubeDownloader extends Downloader {
  static const channelIdIdentifierMeaning = 'YouTube Channel ID';

  static Platform getPlatform() => Platform(
        (p) => p
          ..id = 'youtube'
          ..uri = Uri.parse('https://www.youtube.com'),
      );

  @override
  Platform get platform => getPlatform();

  // TODO: switch back to 1 once we can get the publishDate instead of the
  // uploadDate from youtube_explode. This will make sure the ordering in
  // slidingWindow will be correct, and the assert won't fail. See
  // https://github.com/Hexer10/youtube_explode_dart/issues/68
  @override
  int get slidingWindowSize => 10;

  static SourceCollection createChannelIdSourceCollection(
          String displayName, String identifier) =>
      Downloader.createSourceCollection(
          displayName, getPlatform(), channelIdIdentifierMeaning, identifier);

  final yt_explode.YoutubeExplode _youtubeExplode;

  YoutubeDownloader([yt_explode.YoutubeExplode youtubeExplode])
      : _youtubeExplode = youtubeExplode ?? yt_explode.YoutubeExplode(),
        super();

  @override
  Future<MediaFile> download(Media media,
      {Function(double progress) callback}) async {
    final videoId = getSourceUniqueId(media);

    // Set up a temporary file to hold the contents of the download
    final path =
        p.join(memoryFileSystem.systemTempDirectory.path, '$videoId.mp4');
    final file = memoryFileSystem.file(path);

    await _download(videoId, file, callback);
    return MediaFile(media, file);
  }

  // Download the video with the specified id to the specified file, which will
  // be opened for write and when finished, closed and returned.
  Future<File> _download(
      String id, File file, Function(double progress) callback) async {
    // Get the video media stream.
    var manifest = await _youtubeExplode.videos.streamsClient.getManifest(id);

    // Get the first muxed video (the one with the lowest bitrate to save space
    // and make downloads faster for now). note that mediaStreams.muxed will
    // never be the best quality. To achieve that, we'd need to merge the audio
    // and video streams.
    var videoStreamInfo = manifest.muxed.firstWhere(
        (streamInfo) => streamInfo.container == yt_explode.StreamContainer.mp4);

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
        final stream =
            _youtubeExplode.videos.streamsClient.get(videoStreamInfo);
        await for (var data in stream) {
          count += data.length;
          var progress = count / len;
          if (progress != oldProgress) {
            callback?.call(progress);
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
        // print(e);

        // Clear the file and start over
        await file.writeAsBytes([]);
        output = file.openWrite(mode: FileMode.writeOnlyAppend);
        count = 0;
        oldProgress = 1;
      }
    }
    await output.close();
    return file;
  }

  @override
  Stream<Media> allMedia(SourceCollection sourceCollection) {
    if (sourceCollection.platform != getPlatform()) {
      throw 'sourceCollection platform mismatch';
    }
    if (sourceCollection.identifierMeaning != channelIdIdentifierMeaning) {
      throw 'The Youtube downloader currently only supports ChannelId SourceCollections';
    }
    final channelId = yt_explode.ChannelId(sourceCollection.identifier);
    final stream = _youtubeExplode.channels.getUploads(channelId);

    return stream.map((upload) => Media((v) => v
      ..title = upload.title
      ..description = upload.description
      ..duration = upload.duration
      ..source = Source(
        (s) => s
          ..id = upload.id.toString()
          ..uri = Uri.parse('https://www.youtube.com/watch?v=${upload.id}')
          ..platform = getPlatform().toBuilder()
          ..releaseDate = upload.uploadDate.toUtc(),
      ).toBuilder()));
  }

  @override
  void close() {
    _youtubeExplode.close();
    super.close();
  }

  @override
  String getSourceUniqueId(Media media) =>
      yt_explode.VideoId.parseVideoId(media.source.uri.toString());

  @override
  Feed createEmptyFeed(SourceCollection sourceCollection) {
    // TODO: implement createEmptyFeed with actual data from youtube
    return Examples.emptyFeed.rebuild((b) => b
      ..title = sourceCollection.identifier
      ..subtitle = '${sourceCollection.identifier} feed)');
  }
}
