import 'dart:io';
import 'dart:convert' show json;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:googleapis/youtube/v3.dart' hide Video;
import 'package:vidlib/vidlib.dart';
import 'package:built_collection/built_collection.dart';

import '../bin/main.dart';

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

void main() {
  group('YouTube cloner', () {
    test('gets all video upload metadata for a channel', () async {
      final mockApi = MockYoutubeApi();

      // Make sure the initial channel request will succeed
      when(mockApi.channels
              .list('contentDetails, snippet', id: 'TEST_CHANNEL_ID'))
          .thenAnswer((_) => Future.value(FakeChannelListResponse()));

      // Mock the three API requests required to return all the test data.
      // The data has been modified so that the third request has '' as
      // nextPage, which implies it's the last page.
      when(mockApi.playlistItems.list(
        'contentDetails, snippet',
        playlistId: 'TEST_UPLOADS_PLAYLIST_ID',
        pageToken: null,
        maxResults: 50,
      )).thenAnswer((_) async {
        return responseWithJson(
            'test/resources/playlist_items_list_response_1.json');
      });
      when(mockApi.playlistItems.list(
        'contentDetails, snippet',
        playlistId: 'TEST_UPLOADS_PLAYLIST_ID',
        pageToken: 'CDIQAA',
        maxResults: 50,
      )).thenAnswer((_) async {
        return responseWithJson(
            'test/resources/playlist_items_list_response_2.json');
      });
      when(mockApi.playlistItems.list(
        'contentDetails, snippet',
        playlistId: 'TEST_UPLOADS_PLAYLIST_ID',
        pageToken: 'CGQQAA',
        maxResults: 50,
      )).thenAnswer((_) async {
        return responseWithJson(
            'test/resources/playlist_items_list_response_3.json');
      });

      final result = await allUploads(mockApi, 'TEST_CHANNEL_ID').toList();

      // Verify that the results are correctly returned in descending order by
      // date. The YouTube API often returns videos out of order (and so does
      // our test data)
      final copy = List.from(result);
      copy.sort((a, b) => b.date.compareTo(a.date));
      expect(result, copy);

      final serializableResult = BuiltList<Video>(result);

      // Uncomment these lines to copy the results of the test for use in
      // modifying the expected result file.
      // final serializedResult = jsonSerializers.serialize(serializableResult);
      // final encodedResult = json.encode(serializedResult);

      final expectedResultFile =
          await File('test/resources/all_uploads_expected.json');
      final expectedResultJsonString = await expectedResultFile.readAsString();
      final decodedExpectedResult = json.decode(expectedResultJsonString);
      final expectedResult = jsonSerializers.deserialize(decodedExpectedResult);

      expect(serializableResult, expectedResult);
    });
  });
}
