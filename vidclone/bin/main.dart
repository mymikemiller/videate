import 'dart:io';
import 'package:aws_s3_client/aws_s3.dart';
import 'package:file/local.dart';
import 'package:vidlib/vidlib.dart' hide Platform;
import 'cloner.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:path/path.dart' as p;
import 'integrations/cdn77/cdn77_feed_manager.dart';
import 'integrations/cdn77/cdn77_uploader.dart';
import 'integrations/internet_archive/internet_archive_uploader.dart';
import 'integrations/local/json_file_feed_manager.dart';
import 'integrations/local/local_downloader.dart';
import 'integrations/local/save_to_disk_uploader.dart';
import 'integrations/youtube/youtube_downloader.dart';
import 'package:file/file.dart' as file;
import 'dart:convert';

final forcedCloneStartDate =
    null; // DateTime.parse('2020-07-22T00:00:00.000Z');
const feedName = 'tdts';
const youtube_channel_ids = {
  'gamegrumps': 'UC9CuvdOVfMPvKCiwdGKL3cQ',
  'nsp': 'UCs7yDP7KWrh0wd_4qbDP32g',
  'tdts': 'UCNl_4FD4qQdZZJMzAM7LJqQ',
};

void main(List<String> arguments) async {
  // Load environment variables from local .env file
  load();

  print('');

  final internetArchiveAccessKey =
      getEnvVar('INTERNET_ARCHIVE_ACCESS_KEY', env);
  final internetArchiveSecretKey =
      getEnvVar('INTERNET_ARCHIVE_SECRET_KEY', env);
  final home = Platform.environment['HOME'];
  final videosBaseDirectory = Directory('$home/web/videos');
  final feedsBaseDirectory = Directory('$home/web/feeds');

  final downloader = YoutubeDownloader();
  // final downloader = LocalDownloader();

  final sourceCollection = YoutubeDownloader.createChannelIdSourceCollection(
      youtube_channel_ids[feedName]);
  // final sourceCollection = LocalDownloader.createFilePathSourceCollection(
  //     p.join(videosBaseDirectory.path, downloader.platform.id, feedName));

  // final uploader = InternetArchiveUploader(internetArchiveAccessKey,
  //     internetArchiveSecretKey);
  // final uploader = SaveToDiskUploader(LocalFileSystem().directory(
  //     p.join(videosBaseDirectory.path, downloader.platform.id, feedName)));
  final uploader = Cdn77Uploader();

  // Save the feed to a json file
  final jsonFilePath = p.join(feedsBaseDirectory.path, '$feedName.json');
  final feedManager = await JsonFileFeedManager(jsonFilePath);
  // final feedManager = Cdn77FeedManager('${feedName}.json');

  // Create the Cloner
  final cloner = Cloner(downloader, uploader, feedManager);

  // Get the latest feed data, or create an empty feed if necessary
  if (!await feedManager.populate()) {
    feedManager.feed = downloader.createEmptyFeed(sourceCollection);
  }

  if (downloader is LocalDownloader) {
    // Special case for LocalDownloader, where we always "download" everything.
    // This is necessary because all local videos have the same releaseDate.
    await for (var servedVideo in cloner.cloneCollection(sourceCollection)) {
      print('(Local) Cloned video available at ${servedVideo.uri}');
    }
  } else {
    // Figure out how far back in time we need to clone. This value will be
    // null if the feed is currently empty.
    final mostRecentVideoAlreadyInFeed = feedManager.feed.mostRecentVideo;

    if (forcedCloneStartDate == null && mostRecentVideoAlreadyInFeed == null) {
      // Clone the source's most recent video
      final servedVideo = await cloner.cloneMostRecentVideo(sourceCollection);
      print('(First) Cloned video available at ${servedVideo.uri}');
    } else {
      // Clone only videos newer than the most recent video we already have
      var cloneStartDate;
      if (forcedCloneStartDate != null) {
        print('Forcing clone to begin at start date $forcedCloneStartDate');
        cloneStartDate = forcedCloneStartDate;
      } else {
        print(
            'Cloning videos newer than the most recent video in feed (${mostRecentVideoAlreadyInFeed.video.title})');
        cloneStartDate = mostRecentVideoAlreadyInFeed.video.source.releaseDate;
      }
      await for (var servedVideo
          in cloner.cloneCollection(sourceCollection, cloneStartDate)) {
        print('(Additional) Cloned video available at ${servedVideo.uri}');
      }
    }
  }

  cloner.close();
}
