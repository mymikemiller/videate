import 'dart:io';
import 'package:file/memory.dart';
import 'dart:async';
import 'package:vidlib/vidlib.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import '../../downloader.dart';
import 'package:path/path.dart' as p;

final memoryFileSystem = MemoryFileSystem();

class YoutubeDownloader extends Downloader {
  // The channelId of the user whose videos to download, e.g.
  // UC9CuvdOVfMPvKCiwdGKL3cQ. To find the channelId for youtube channels where
  // the user's username instead of the channelId is listed in the url, view
  // source on the channel page and search for externalId or
  // data-channel-external-id. Alternatively, use the YouTube API if you know
  // the user's username:
  // https://www.googleapis.com/youtube/v3/channels?key={YOUR_API_KEY}&forUsername={USERNAME}&part=id
  yt_explode.ChannelId channelId;

  @override
  void configure(ClonerTaskArgs downloaderArgs) {
    final channelIdString = downloaderArgs.get('channelId');
    channelId = yt_explode.ChannelId(channelIdString);
  }

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

  final yt_explode.YoutubeExplode _youtubeExplode;

  YoutubeDownloader([yt_explode.YoutubeExplode youtubeExplode])
      : _youtubeExplode = youtubeExplode ?? yt_explode.YoutubeExplode(),
        super();

  @override
  Future<MediaFile> downloadMedia(Media media,
      [Function(double progress) callback]) async {
    final videoId = getSourceUniqueId(media);

    // Set up a temporary file to hold the contents of the download
    final tempDirectory = createTempDirectory(memoryFileSystem);
    final path = p.join(tempDirectory.path, '$videoId.mp4');
    final file = memoryFileSystem.file(path);
    // Get the video media stream.
    var manifest =
        await _youtubeExplode.videos.streamsClient.getManifest(videoId);

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
        print('Encountered error downloading video. Starting over.');
        await file.writeAsBytes([]);
        output = file.openWrite(mode: FileMode.writeOnlyAppend);
        count = 0;
        oldProgress = 1;
      }
    }
    await output.close();
    return MediaFile(media, file);
  }

  @override
  Stream<Media> allMedia() {
    if (channelId == null) {
      throw 'The Youtube downloader currently only supports ChannelId SourceCollections';
    }
    final stream = _youtubeExplode.channels.getUploads(channelId);

    DateTime previousVideoPublishDate;
    Media previousMedia;

    return stream.asyncMap((upload) async {
      // The publish date and the video description don't come through when
      // using channels.getUploads, so we have to fetch each video individually
      final video = await _youtubeExplode.videos.get(upload.id);
      var publishDate = video.publishDate.toUtc();

      if (publishDate == previousVideoPublishDate) {
        // youtube_explode returns the same time (midnight UTC) for all
        // publishDates, but we need the publishDate to match the order of
        // videos returned by youtube_expolode. So, if we get multiple videos
        // in a row with the same publishDate, we modify the publishDate to
        // decrement the time a little from the last Media we returned (we
        // decrement the date from the last Media returned becuse it's already
        // been decremented the correct number of times from the videos before
        // it if more than two share a publishDate)
        publishDate = previousMedia.source.releaseDate
            .subtract(Duration(microseconds: 1));
      }

      final media = Media((v) => v
        ..title = upload.title
        ..description = video.description // upload.description is  ""
        ..duration = upload.duration
        ..source = Source((s) => s
          ..id = upload.id.toString()
          ..uri = Uri.parse('https://www.youtube.com/watch?v=${upload.id}')
          ..platform = getPlatform().toBuilder()
          ..releaseDate = publishDate).toBuilder());

      previousVideoPublishDate = publishDate.toUtc();
      previousMedia = media;
      return media;
    });
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
  Future<Feed> createEmptyFeed() async {
    final metadata = await _youtubeExplode.channels.get(channelId);

    // The about page is necessary to get the channel description
    final aboutPage = await _youtubeExplode.channels.getAboutPage(channelId);

    return Examples.emptyFeed.rebuild((b) => b
      ..title = metadata.title
      ..description = aboutPage.description
      ..imageUrl = metadata.logoUrl
      ..subtitle = ''
      ..link = metadata.url
      ..author = ''
      ..email = '');
  }
}
