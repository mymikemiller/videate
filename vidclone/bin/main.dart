import 'dart:io';
import 'package:vidlib/vidlib.dart';
import 'cloner.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:path/path.dart' as p;
import 'integrations/local/json_file_feed_manager.dart';
import 'integrations/local/save_to_disk_uploader.dart';
import 'integrations/youtube/channel_source_collection.dart';
import 'integrations/youtube/youtube_downloader.dart';

void main(List<String> arguments) async {
  // Load environment variables from local .env file
  load();
  final key = getEnvVar('GOOGLE_API_KEY', env);
  final home = Platform.environment['HOME'];
  final videosBaseDirectory = Directory('$home/web/videos');
  final feedsBaseDirectory = Directory('$home/web/feeds');

  // Download from YouTube
  final downloader = YoutubeDownloader.fromApiKey(key);

  // Save the file under the user's home directory
  final uploader = SaveToDiskUploader(
      Directory(p.join(videosBaseDirectory.path, downloader.id)));

  // Save the feed to a json file
  final nspJsonFilePath = p.join(feedsBaseDirectory.path, 'nsp.json');
  final feedManager = await JsonFileFeedManager.createOrOpen(nspJsonFilePath);

  // Download from YouTube and "upload" by saving to a local file
  final cloner = Cloner(downloader, uploader, feedManager);

  // Game Grumps: UC9CuvdOVfMPvKCiwdGKL3cQ
  // Ninja Sex Party: UCs7yDP7KWrh0wd_4qbDP32g
  final sourceCollection =
      YoutubeChannelSourceCollection('UCs7yDP7KWrh0wd_4qbDP32g');

  // Figure out how far back in time we need to clone. This value will be null
  // if the feed is currently empty.
  final mostRecentVideoInFeed = feedManager.feed.mostRecentVideo;

  if (mostRecentVideoInFeed == null) {
    // Clone the most recent video
    final servedVideo = await cloner.cloneMostRecentVideo(sourceCollection);
    print('Finished cloning ${servedVideo?.uri ?? "video"}');
  } else {
    // Clone only videos later than the most recent video
    final cloneStartDate = mostRecentVideoInFeed.video.sourceReleaseDate;
    await for (var servedVideo
        in cloner.cloneVideosAfter(cloneStartDate, sourceCollection)) {
      print('Finished cloning ${servedVideo.uri ?? "video"}');
    }
  }

  print('Done');
}
