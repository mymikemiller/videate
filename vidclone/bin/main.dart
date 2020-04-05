import 'dart:async';
import 'dart:io' show Platform;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/youtube/v3.dart' hide Video;
import 'package:vidlib/vidlib.dart';

// The API Key obtained from the Google Developers Console.
final apiKey = getEnvVar('GOOGLE_API_KEY');

// We use 50, Youtube's max for this value.
final maxApiResultsPerCall = 50;

// The maximum number of videos returned by the API before yeilding the earliest in the window.
// This is necessary because videos are returned in upload order, not publish order. We're specifying
// here that we can expect any set of videos this size returned consecutively by
// the API to include the most recent video of any videos that have yet to be returned
// (in orther words, we're expecting that creators will never upload this many
// videos before publishing an old video)
final slidingWindowSize = 99;

String getEnvVar(String key) {
  final value = Platform.environment[key];
  if (value == null) {
    throw 'Environment variable not set: $key';
  }
  return value;
}

// Return a stream of all YouTube videos in reverse publishedAt date order
// (most recently published video first)
Stream<Video> allUploads(YoutubeApi api, String channelId) async* {
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
  var nextPageToken; // Null (default value) means we haven't started, '' means we're done
  var playlistItemsResponse;
  var slidingWindow = <Video>[];
  var previouslyYielded;

  while (nextPageToken == null || nextPageToken.isNotEmpty) {
    playlistItemsResponse = await api.playlistItems.list(
        'contentDetails, snippet',
        playlistId: uploadsPlaylistId,
        pageToken: nextPageToken,
        maxResults: maxApiResultsPerCall);

    // To save API responses as json for the purposes of making tests,
    // uncomment this line and break on the next line to copy the json response
    // to the clipboard
    // final encoded = json.encode(playlistItemsResponse);

    nextPageToken = playlistItemsResponse.nextPageToken;

    // Add the videos in this page one by one to the sliding window, keeping
    // them in date order, picking off from the sliding window when it gets too full
    for (var playlistItem in playlistItemsResponse.items) {
      final video = Video((b) => b
        ..title = playlistItem.snippet.title
        ..description = playlistItem.snippet.description
        ..url =
            'https://www.youtube.com/watch?v=${playlistItem.snippet.resourceId.videoId}'
        ..date = playlistItem.snippet.publishedAt);

      // We want the videos in slidingWindow to be in reverse date order (they
      // generally are returned by the YouTube API in this order, but often
      // videos come back slightly out of order likely because they're returned
      // in upload order not publish order), so find the first video that has a
      // date older than this video and add this video right before it
      // (otherwise add this video at the end if we don't find any out of order
      // videos)
      var i;
      for (i = 0; i < slidingWindow.length; i++) {
        if (video.date.compareTo(slidingWindow[i].date) > 0) {
          break;
        }
      }

      slidingWindow.insert(i, video);

      if (slidingWindow.length > slidingWindowSize) {
        // Yield the most recent video in the sliding window
        final toYield = slidingWindow.removeAt(0);
        // Assert that we're always yielding in reverse date order
        assert(previouslyYielded == null ||
            previouslyYielded.date.compareTo(toYield.date) > 0);
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
        previouslyYielded.date.compareTo(video.date) > 0);
    previouslyYielded = video;
    yield video;
  }
}

void main(List<String> arguments) async {
  final client = auth.clientViaApiKey(apiKey);
  final api = YoutubeApi(client);
  await for (var video in allUploads(api, 'UC9CuvdOVfMPvKCiwdGKL3cQ')) {
    print(video);
  }
}
