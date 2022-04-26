import 'dart:io' as io;
import 'package:file/local.dart';
import 'package:vidlib/vidlib.dart' hide Platform;
import 'cloner.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'integrations/cdn77/cdn77_feed_manager.dart';
import 'integrations/cdn77/cdn77_uploader.dart';
import 'integrations/internet_archive/internet_archive_cli_uploader.dart';
import 'integrations/internet_computer/internet_computer_feed_manager.dart';
import 'integrations/local/json_file_feed_manager.dart';
import 'integrations/local/local_downloader.dart';
import 'integrations/local/null_uploader.dart';
import 'integrations/local/save_to_disk_uploader.dart';
import 'integrations/media_converters/ffmpeg_media_converter.dart';
import 'integrations/media_converters/null_media_converter.dart';
import 'integrations/youtube/youtube_downloader.dart';
import 'dart:convert';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

final forcedCloneStartDate = null;
// null; // DateTime.parse('2020-07-22T00:00:00.000Z');

void main(List<String> arguments) async {
  // Load environment variables from local .env file
  load();

  print('starting clone');

  final home = io.Platform.environment['HOME'];
  final localFileSystem = LocalFileSystem();

  // The first argument specifies the cloner configuration file to override the
  // default with
  final clonerConfigurationsFilePath = arguments.asMap().containsKey(0)
      ? arguments[0]
      : '$home/videate/cloner_configs.json';
  final clonerConfigurationsFile =
      localFileSystem.file(clonerConfigurationsFilePath);

  final internetArchiveAccessKey =
      getEnvVar('INTERNET_ARCHIVE_ACCESS_KEY', env);
  final internetArchiveSecretKey =
      getEnvVar('INTERNET_ARCHIVE_SECRET_KEY', env);
  final mediaBaseDirectory = localFileSystem.directory('$home/web/media');
  // final feedsBaseDirectory = localFileSystem.directory('$home/web/feeds');

  final downloaders = [
    YoutubeDownloader(),
    LocalDownloader(),
  ];
  final mediaConverters = [
    NullMediaConverter(),
    FfmpegMediaConverter(),
  ];
  final uploaders = [
    NullUploader(mediaBaseDirectory),
    SaveToDiskUploader(mediaBaseDirectory),
    Cdn77Uploader(),
    InternetArchiveCliUploader(
        internetArchiveAccessKey, internetArchiveSecretKey),
  ];
  final feedManagers = [
    JsonFileFeedManager(),
    Cdn77FeedManager(),
    InternetComputerFeedManager(),
  ];

  // Generate a map to the downloaders keyed on the downloader's id.
  final downloaderMap = {for (var e in downloaders) e.platform.id: e};
  final mediaConverterMap = {for (var e in mediaConverters) e.id: e};
  final uploaderMap = {for (var e in uploaders) e.id: e};
  final feedManagerMap = {for (var e in feedManagers) e.id: e};

  // Get the cloner configurations, which tell us what to clone and how
  final clonerConfigurationsString =
      clonerConfigurationsFile.readAsStringSync();
  final clonerConfigurationsObj = json.decode(clonerConfigurationsString);
  BuiltList<ClonerConfiguration> clonerConfigurations =
      jsonSerializers.deserialize(clonerConfigurationsObj,
          specifiedType: FullType(BuiltList, [FullType(ClonerConfiguration)]));

  // Verify that all feed destinations are unique since the file doesn't
  // guarantee it, but we want to avoid writing to the same feed twice. We
  // naively assume two feed destinations are unique only if all feedManager
  // args are identical and thus the feedManagers compare as equal.
  final duplicateFeeds = getDuplicatesByAccessor(
      clonerConfigurations,
      (ClonerConfiguration clonerConfiguration) =>
          clonerConfiguration.feedManager);
  if (duplicateFeeds.isNotEmpty) {
    throw 'Cloner Configuration file contains duplicate feed(s): [${duplicateFeeds.join(", ")}]';
  }

  for (var clonerConfiguration in clonerConfigurations) {
    final feedManager = feedManagerMap[clonerConfiguration.feedManager.id]
      ..configure(clonerConfiguration.feedManager);
    final downloader = downloaderMap[clonerConfiguration.downloader.id]
      ..configure(clonerConfiguration.downloader);
    final mediaConverter =
        mediaConverterMap[clonerConfiguration.mediaConverter.id]
          ..configure(clonerConfiguration.mediaConverter);
    final uploader = uploaderMap[clonerConfiguration.uploader.id]
      ..configure(clonerConfiguration.uploader);

    final cloner = Cloner(feedManager, downloader, mediaConverter, uploader);

    print('Processing ${cloner.feedManager.id} ${cloner.feedManager.feedName}');

    // Get the latest feed data, or create an empty feed if necessary
    if (!await cloner.feedManager.populate()) {
      cloner.feedManager.feed = await cloner.downloader.createEmptyFeed();
    }

    if (cloner.downloader is LocalDownloader) {
      // Special case for LocalDownloader, where we always "download"
      // everything regardless of date. This is necessary because all local
      // files have the same hard-coded releaseDate.
      await for (var servedMedia in cloner.cloneCollection()) {
        print('(Local) Cloned media available at ${servedMedia.uri}');
      }
    } else {
      // Figure out how far back in time we need to clone. This value will be
      // null if the feed is currently empty.
      final mostRecentMediaAlreadyInFeed =
          cloner.feedManager.feed.mostRecentMedia;

      if (forcedCloneStartDate == null &&
          mostRecentMediaAlreadyInFeed == null) {
        // Clone the source's most recent media
        final servedMedia = await cloner.cloneMostRecentMedia();
        print('(First) Cloned media available at ${servedMedia.uri}');
      } else {
        // Clone only media newer than the most recent media we already have
        var cloneStartDate;
        if (forcedCloneStartDate != null) {
          print(
              'Forcing clone of all videos released on or after $forcedCloneStartDate, even if they\'re already in the feed. Duplicates may occur.');
          cloneStartDate = forcedCloneStartDate;
        } else {
          print(
              'Cloning media newer than the most recent media in feed (${mostRecentMediaAlreadyInFeed.media.title})');
          cloneStartDate =
              mostRecentMediaAlreadyInFeed.media.source.releaseDate;
        }
        await for (var servedMedia in cloner.cloneCollection(cloneStartDate)) {
          print('(Additional) Cloned media available at ${servedMedia.uri}');
        }
      }
    }
  }

  // Close all the ClonerTasks
  [downloaders, mediaConverters, uploaders, feedManagers]
      .expand((i) => i)
      .forEach((clonerTask) {
    clonerTask.close();
  });

  // This exit statement is only necessary because youtubeExplode has a timer
  //that isn't properly closed. This can be removed once the following issue is
  //fixed: https://github.com/Hexer10/youtube_explode_dart/issues/61 throw
  //('\nDONE - IGNORE THIS EXCEPTION');
}
