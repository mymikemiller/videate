import 'dart:io';
import 'package:aws_s3_client/aws_s3.dart';
import 'package:file/local.dart';
import 'package:vidlib/vidlib.dart' hide Platform;
import 'cloner.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:path/path.dart' as p;
import 'downloader.dart';
import 'integrations/cdn77/cdn77_feed_manager.dart';
import 'integrations/cdn77/cdn77_uploader.dart';
import 'integrations/internet_archive/internet_archive_uploader.dart';
import 'integrations/local/json_file_feed_manager.dart';
import 'integrations/local/local_downloader.dart';
import 'integrations/local/save_to_disk_uploader.dart';
import 'integrations/media_converters/hevc_media_converter.dart';
import 'integrations/youtube/youtube_downloader.dart';
import 'package:file/file.dart' as file;
import 'dart:convert';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'media_converter.dart';

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
  final mediaBaseDirectory = Directory('$home/web/media');
  final feedsBaseDirectory = Directory('$home/web/feeds');
  final sourceCollectionsFile = File('$home/videate/source_collections.json');

  final downloaders = [YoutubeDownloader(), LocalDownloader()];

  // Generate a map to the downloaders keyed on the downloader's id.
  final downloaderMap = {for (var e in downloaders) e.platform.id: e};

  // Get the list of sourceCollections to clone
  final sourceCollectionsString = sourceCollectionsFile.readAsStringSync();
  final sourceCollectionsObj = json.decode(sourceCollectionsString);
  Map<String, SourceCollection> sourceCollectionMap =
      sourceCollectionsObj.map<String, SourceCollection>((String k, dynamic v) {
    final sourceCollection = jsonSerializers.deserializeWith<SourceCollection>(
        SourceCollection.serializer, v);
    return MapEntry<String, SourceCollection>(k, sourceCollection);
  });

  // final sourceCollection = YoutubeDownloader.createChannelIdSourceCollection(
  //     youtube_channel_ids[feedName]);
  // final sourceCollection = LocalDownloader.createFilePathSourceCollection(
  //     p.join(mediaBaseDirectory.path, downloader.platform.id, feedName));
  // final list =
  //     BuiltList<SourceCollection>([sourceCollection, sourceCollection2]);
  // final listJson = jsonSerializers.serialize(list);
  // final listString = json.encode(listJson);

  final mediaConverter = HevcMediaConverter();
  final mediaConversionArgs =
      HevcMediaConverter.createArgs(height: 240, crf: 30);

  // The uploader depends on the downloader, so it's created in the loop below
  var uploader;

  final feedManager = await JsonFileFeedManager(
      p.join(feedsBaseDirectory.path, '$feedName.json'));
  // final feedManager = Cdn77FeedManager('${feedName}.json');

  for (var entry in sourceCollectionMap.entries) {
    final feedName = entry.key;
    final sourceCollection = entry.value;
    print(
        'Processing "$feedName" source collection: ${sourceCollection.displayName}');

    final downloader = downloaderMap[sourceCollection.platform.id];

    // final uploader = InternetArchiveUploader(internetArchiveAccessKey,
    //     internetArchiveSecretKey);
    uploader = SaveToDiskUploader(LocalFileSystem().directory(
        p.join(mediaBaseDirectory.path, downloader.platform.id, feedName)));
    // final uploader = Cdn77Uploader();

    // Create the Cloner
    final cloner = Cloner(downloader, mediaConverter, uploader, feedManager);

    // Get the latest feed data, or create an empty feed if necessary
    if (!await feedManager.populate()) {
      feedManager.feed = downloader.createEmptyFeed(sourceCollection);
    }

    if (downloader is LocalDownloader) {
      // Special case for LocalDownloader, where we always "download"
      // everything. This is necessary because all local files have the same
      // hard-coded releaseDate.
      await for (var servedMedia
          in cloner.cloneCollection(sourceCollection, mediaConversionArgs)) {
        print('(Local) Cloned media available at ${servedMedia.uri}');
      }
    } else {
      // Figure out how far back in time we need to clone. This value will be
      // null if the feed is currently empty.
      final mostRecentMediaAlreadyInFeed = feedManager.feed.mostRecentMedia;

      if (forcedCloneStartDate == null &&
          mostRecentMediaAlreadyInFeed == null) {
        // Clone the source's most recent media
        final servedMedia = await cloner.cloneMostRecentMedia(
            sourceCollection, mediaConversionArgs);
        print('(First) Cloned media available at ${servedMedia.uri}');
      } else {
        // Clone only media newer than the most recent media we already have
        var cloneStartDate;
        if (forcedCloneStartDate != null) {
          print('Forcing clone to begin at start date $forcedCloneStartDate');
          cloneStartDate = forcedCloneStartDate;
        } else {
          print(
              'Cloning media newer than the most recent media in feed (${mostRecentMediaAlreadyInFeed.media.title})');
          cloneStartDate =
              mostRecentMediaAlreadyInFeed.media.source.releaseDate;
        }
        await for (var servedMedia in cloner.cloneCollection(
            sourceCollection, mediaConversionArgs, cloneStartDate)) {
          print('(Additional) Cloned media available at ${servedMedia.uri}');
        }
      }
    }
  }

  for (var downloader in downloaders) {
    downloader.close();
  }
  mediaConverter.close();
  uploader.close();
  feedManager.close();

  // This exit statement is only necessary because youtubeExplode has a timer
  //that isn't properly closed. This can be removed once the following issue is
  //fixed: https://github.com/Hexer10/youtube_explode_dart/issues/61
  // throw ('\nDONE - IGNORE THIS EXCEPTION');
}
