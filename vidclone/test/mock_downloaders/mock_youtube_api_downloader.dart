import 'dart:convert';
import 'dart:io';
import 'package:googleapis/youtube/v3.dart' hide Video;
import 'package:mockito/mockito.dart';
import 'package:vidlib/src/models/video.dart';
import 'package:vidlib/vidlib.dart';
import '../../bin/integrations/youtube/youtube_downloader.dart';
import '../../bin/source_collection.dart';

// This file is no longer used since we're using YoutubeExplode, but is left
// here for easy testing in case we add API calls back in.
//
// MockYoutubeDownloader implements, not extends, YoutubeDownloader because
// YoutubeDownloader's only constructors are factory constructors which can't
// be extended. So we implement it instead and send all calls to a delegate we
// create which uses an API we can mock. See
// https://stackoverflow.com/questions/18564676/extending-a-class-with-only-one-factory-constructor
class MockYoutubeApiDownloader implements YoutubeDownloader {
  @override
  Platform get platform => Platform(
        (p) => p
          ..id = 'youtube'
          ..uri = Uri(path: 'https://www.youtube.com'),
      );

  final YoutubeDownloader _delegate;
  static final mockApi = MockYoutubeApi();

  MockYoutubeApiDownloader() : _delegate = YoutubeDownloader() {
    // Make sure the initial channel request will succeed
    when(mockApi.channels
            .list('contentDetails, snippet', id: 'UC9CuvdOVfMPvKCiwdGKL3cQ'))
        .thenAnswer((_) => Future.value(FakeChannelListResponse()));

    // Mock the three API requests required to return all the test data.
    // The data has been modified so that the third request has null as
    // nextPage, which implies it's the last page.
    when(mockApi.playlistItems.list(
      'contentDetails, snippet',
      playlistId: 'TEST_UPLOADS_PLAYLIST_ID',
      pageToken: '',
      maxResults: 50,
    )).thenAnswer((_) async {
      return responseWithJson(
          'test/resources/youtube/playlist_items_list_response_1.json');
    });
    when(mockApi.playlistItems.list(
      'contentDetails, snippet',
      playlistId: 'TEST_UPLOADS_PLAYLIST_ID',
      pageToken: 'CDIQAA',
      maxResults: 50,
    )).thenAnswer((_) async {
      return responseWithJson(
          'test/resources/youtube/playlist_items_list_response_2.json');
    });
    when(mockApi.playlistItems.list(
      'contentDetails, snippet',
      playlistId: 'TEST_UPLOADS_PLAYLIST_ID',
      pageToken: 'CGQQAA',
      maxResults: 50,
    )).thenAnswer((_) async {
      return responseWithJson(
          'test/resources/youtube/playlist_items_list_response_3.json');
    });
  }

  @override
  int get slidingWindowSize => _delegate.slidingWindowSize;

  @override
  Stream<Video> allVideos(SourceCollection sourceCollection) =>
      _delegate.allVideos(sourceCollection);

  @override
  String getSourceUniqueId(Video video) => _delegate.getSourceUniqueId(video);

  @override
  Future<Video> mostRecentVideo(SourceCollection sourceCollection) =>
      _delegate.mostRecentVideo(sourceCollection);

  @override
  Stream<Video> videosAfter(DateTime date, SourceCollection sourceCollection) =>
      _delegate.videosAfter(date, sourceCollection);

  @override
  Future<VideoFile> download(Video video,
          [void Function(double progress) progressCallback]) =>
      _delegate.download(video);

  @override
  void close() {
    // do nothing
  }

  @override
  Stream<Video> allVideosInOrder(SourceCollection sourceCollection) {
    return _delegate.allVideosInOrder(sourceCollection);
  }
}

Future<PlaylistItemListResponse> responseWithJson(String filePath) async {
  final testResonseJsonFile = await File(filePath);
  final testResponseJson =
      json.decode(await testResonseJsonFile.readAsString());
  return PlaylistItemListResponse.fromJson(testResponseJson);
}

class MockYoutubeApi extends Mock implements YoutubeApi {
  ChannelsResourceApi mChannels = MockChannelsResourceApi();
  PlaylistItemsResourceApi mPlaylistItems = MockPlaylistItemsResourceApi();

  @override
  ChannelsResourceApi get channels {
    return mChannels;
  }

  @override
  PlaylistItemsResourceApi get playlistItems {
    return mPlaylistItems;
  }
}

class FakeChannelSnippet extends Fake implements ChannelSnippet {
  @override
  String get description => 'Fake Channel Description';
}

class FakeChannelContentDetailsRelatedPlaylists extends Fake
    implements ChannelContentDetailsRelatedPlaylists {
  @override
  String get uploads => 'TEST_UPLOADS_PLAYLIST_ID';
}

class FakeContentDetails extends Fake implements ChannelContentDetails {
  @override
  ChannelContentDetailsRelatedPlaylists get relatedPlaylists =>
      FakeChannelContentDetailsRelatedPlaylists();
}

class FakeChannel extends Fake implements Channel {
  @override
  ChannelSnippet get snippet => FakeChannelSnippet();

  @override
  ChannelContentDetails get contentDetails => FakeContentDetails();
}

class MockChannelsResourceApi extends Mock implements ChannelsResourceApi {}

class MockPlaylistItemsResourceApi extends Mock
    implements PlaylistItemsResourceApi {}

class FakeChannelListResponse extends Fake implements ChannelListResponse {
  @override
  List<Channel> get items {
    return [
      FakeChannel(),
    ];
  }
}

class FakePlaylistItemsListResponse extends Fake
    implements PlaylistItemListResponse {
  @override
  List<PlaylistItem> get items {
    return [];
  }

  @override
  String get nextPageToken => null;
}