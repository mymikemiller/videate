/* TODO: Add this back in with new youtube_exolode changes
import 'dart:convert';
import 'dart:io';
import 'package:googleapis/youtube/v3.dart' hide Media;
import 'package:http/src/client.dart';
import 'package:mockito/mockito.dart';
import 'package:vidlib/src/models/media.dart';
import 'package:vidlib/vidlib.dart';
import 'package:youtube_explode_dart/src/channels/channel_id.dart';
import '../../bin/integrations/youtube/youtube_downloader.dart';

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
  Stream<Media> allMedia() => _delegate.allMedia();

  @override
  String getSourceUniqueId(Media media) => _delegate.getSourceUniqueId(media);

  @override
  Future<Media> mostRecentMedia() => _delegate.mostRecentMedia();

  @override
  Stream<Media> reverseChronologicalMedia([DateTime after]) =>
      _delegate.reverseChronologicalMedia(after);

  @override
  void configure(ClonerTaskArgs args) => _delegate.configure(args);

  @override
  void close() => _delegate.close();

  @override
  Future<Feed> createEmptyFeed() => _delegate.createEmptyFeed();

  @override
  Client get client => _delegate.client;
  @override
  set client(Client _client) => _delegate.client = _client;

  @override
  dynamic get processRunner => _delegate.processRunner;
  @override
  set processRunner(_processRunner) => _delegate.processRunner = _processRunner;

  @override
  dynamic get processStarter => _delegate.processStarter;
  @override
  set processStarter(_processStarter) =>
      _delegate.processStarter = _processStarter;

  @override
  ChannelId channelId;

  @override
  Future<MediaFile> download(Media media,
          {Function(double progress) callback}) =>
      _delegate.download(media, callback: callback);

  @override
  Future<MediaFile> downloadMedia(Media media,
          [Function(double progress) callback]) =>
      _delegate.downloadMedia(media, callback);
}

Future<PlaylistItemListResponse> responseWithJson(String filePath) async {
  final testResonseJsonFile = File(filePath);
  final testResponseJson =
      json.decode(await testResonseJsonFile.readAsString());
  return PlaylistItemListResponse.fromJson(testResponseJson);
}

class MockYoutubeApi extends Mock implements YouTubeApi {
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
*/
