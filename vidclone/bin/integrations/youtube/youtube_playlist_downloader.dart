import 'dart:io';
import 'package:file/memory.dart';
import 'dart:async';
import 'package:vidlib/vidlib.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import './youtube_downloader.dart';
import 'package:path/path.dart' as p;

final memoryFileSystem = MemoryFileSystem();

class YoutubePlaylistDownloader extends YoutubeDownloader {
  late yt_explode.PlaylistId playlistId;

  @override
  void configure(ClonerTaskArgs downloaderArgs) {
    final playlistIdString = downloaderArgs.get('playlistId');
    playlistId = yt_explode.PlaylistId(playlistIdString);
  }

  @override
  String get id => 'youtube_playlist';

  static Platform getPlatform() => Platform(
        (p) => p
          ..id = 'youtube'
          ..uri = Uri.parse('https://www.youtube.com'),
      );

  @override
  Platform get platform => getPlatform();

  // We should always be able to use "1" here since we don't actually use the
  // date to order videos when returning and so don't need a sliding window
  @override
  int get slidingWindowSize => 1;

  YoutubePlaylistDownloader([yt_explode.YoutubeExplode? youtubeExplode])
      : super(youtubeExplode);

  // Playlist videos are returned in the order they exist in the playlist
  @override
  Stream<Media> allMedia() {
    final stream =
        youtubeExplode.playlists.getVideos(playlistId); // Playlist order

    return stream.asyncMap((upload) async {
      // mike: double check the statement below is true and upload.publishDate
      // and upload.description doesn't exist when using playlists.getVideos as
      // above doesn't exist

      // The publish date and the video description don't come through when
      // using channels.getUploads, so we have to fetch each video individually
      final video = await youtubeExplode.videos.get(upload.id);
      var publishDate = video.publishDate?.toUtc();

      final media = Media((v) => v
        ..title = upload.title
        ..description = video.description // upload.description is ""
        ..duration = upload.duration
        ..source = Source((s) => s
          ..id = upload.id.toString()
          ..uri = Uri.parse('https://www.youtube.com/watch?v=${upload.id}')
          ..platform = getPlatform().toBuilder()
          ..releaseDate = publishDate).toBuilder());

      print('Found playlist media: $media');

      return media;
    });
  }

  @override
  Future<Feed> createEmptyFeed() async {
    // We don't have a channelId because we were initialied with a playlist to
    // download, not an entire channel, so get the channelId from the first
    // video in the playlist. This is obviously not ideal since playlists can
    // contain videos from channels other than the one that owns the playlist,
    // but youtube-explode doens't currently make a playlist's owning channel
    // available
    final stream = youtubeExplode.playlists.getVideos(playlistId);
    final upload = await stream.first;
    var feed = await createEmptyFeedFromChannel(upload.channelId);

    // Instead of the name of the channel, use the playlist's name as the title
    final playlist = await youtubeExplode.playlists.get(playlistId);
    feed = feed.rebuild((f) => f..title = playlist.title);

    return feed;
  }
}
