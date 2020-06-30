import 'dart:io';
import 'package:file/local.dart';
import 'package:vidlib/vidlib.dart' hide Platform;
import 'cloner.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:path/path.dart' as p;
import 'integrations/internet_archive/internet_archive_uploader.dart';
import 'integrations/local/json_file_feed_manager.dart';
import 'integrations/local/save_to_disk_uploader.dart';
import 'integrations/youtube/channel_source_collection.dart';
import 'integrations/youtube/youtube_downloader.dart';
import 'package:file/file.dart' as file;

const example_key = 'nsp';
const example_channel_ids = {
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

  // final uploader = InternetArchiveUploader(internetArchiveAccessKey,
  //     internetArchiveSecretKey);
  final uploader = SaveToDiskUploader(LocalFileSystem()
      .directory(p.join(videosBaseDirectory.path, downloader.platform.id)));

  // Save the feed to a json file
  final demoJsonFilePath =
      p.join(feedsBaseDirectory.path, 'favorites.json'); //'$example_key.json');
  final feedManager = await JsonFileFeedManager.createOrOpen(demoJsonFilePath);

  // Download from YouTube and "upload" by saving to a local file
  final cloner = Cloner(downloader, uploader, feedManager);

  final sourceCollection =
      YoutubeChannelSourceCollection(example_channel_ids[example_key]);
  // final sourceCollection = LocalSourceCollection('test/resources/videos');

  // Figure out how far back in time we need to clone. This value will be null
  // if the feed is currently empty.
  final mostRecentVideoAlreadyInFeed = feedManager.feed.mostRecentVideo;

  if (mostRecentVideoAlreadyInFeed == null) {
    // Clone the source's most recent video
    final servedVideo = await cloner.cloneMostRecentVideo(sourceCollection);
  } else {
    // Clone only videos later than the most recent video we already have
    final cloneStartDate =
        mostRecentVideoAlreadyInFeed.video.source.releaseDate;
    await for (var servedVideo
        in cloner.cloneVideosAfter(cloneStartDate, sourceCollection)) {}
  }

  downloader.close();
}
