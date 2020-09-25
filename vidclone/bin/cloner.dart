import 'dart:io';
import 'package:file/local.dart';
import 'package:vidlib/vidlib.dart';
import 'package:file/memory.dart';
import 'downloader.dart';
import 'feed_manager.dart';
import 'media_converter.dart';
import 'uploader.dart';
import 'package:console/console.dart';

// A fake file system that allows us to interact with downloaded data as though
// it were a file on an actual file system, but it's only ever stored in
// memory.
final memoryFileSystem = MemoryFileSystem();

class Cloner {
  final Downloader _downloader;
  final MediaConverter _mediaConverter;
  final Uploader _uploader;
  final FeedManager _feedManager;

  Cloner(this._downloader, this._mediaConverter, this._uploader,
      this._feedManager);

  // Clones the [Media] by downloading it from the source, converting the file
  // if necessary, uploading it to the destination, then updating a feed.
  //
  // Downloading and uploading will be performed according to this Cloner's
  // Downloader and Upoader behavior.
  //
  // Media that already exist at the uploader's destination will not be cloned.
  // Instead, a [ServedMedia] will be immediately returned.
  Future<ServedMedia> clone(
      Media media, MediaConversionArgs conversionArgs) async {
    final mediaDebugName =
        '${media.source.platform.id} Media ${media.source.id}';
    Console.init();

    // Existence Check
    print(
        '=== Clone: Checking if already cloned: $mediaDebugName (${media.source.releaseDate})===');
    final existenceCheckResult =
        await time(_uploader.getExistingServedMedia, [media]);

    var servedMedia;

    // Short-circuit downloading and uploading if the destination exists
    if (existenceCheckResult.returnValue != null) {
      print(
          'Destination exists. Skipping Download and Upload for ${media.title}.');
      print('=== ⏲  ${existenceCheckResult.time} ⏲  ===');
      servedMedia = existenceCheckResult.returnValue;
    } else {
      print('=== ⏲  ${existenceCheckResult.time} ⏲  ===');

      // Download
      print('=== Clone: Download $mediaDebugName ===');
      final downloadResult =
          await time(_downloader.download, [media], {}, 'callback');
      final downloadedMedia = await downloadResult.returnValue;
      print('=== ⏲  ${downloadResult.time} ⏲ ===');

      // Convert
      print('=== Clone: Convert $mediaDebugName ===');
      final conversionResult = await time(_mediaConverter.convert,
          [downloadedMedia, conversionArgs], {}, 'callback');
      final convertedMedia = await conversionResult.returnValue;
      print('=== ⏲${conversionResult.time} ⏲===');

      // Upload
      print('=== Clone: Upload $mediaDebugName ===');
      final uploadResult = await time(_uploader.upload, [convertedMedia]);
      servedMedia = await uploadResult.returnValue;
      print('=== ⏲${uploadResult.time} ⏲ ===');
      print('served media:${servedMedia.uri}');
    }

    // Update the feed to include the new media
    print('=== Clone: Add $mediaDebugName to Feed ===');
    final feedAddResult = await time(_feedManager.add, [servedMedia]);
    print('=== ⏲${feedAddResult.time} ⏲ ===');

    return servedMedia;
  }

  // This function can be parallelized, but caution should be taken to ensure
  // upload order is maintained if desired, and blocking doesn't occur due to
  // too many simultaneous downloads/uploads.
  Stream<ServedMedia> _cloneAll(
      Iterable<Media> media, MediaConversionArgs conversionArgs) async* {
    for (var media in media) {
      // This can be parallelized, but for simplicity's sake we're awaiting
      // each one here TODO: parallelize this (a queue allowing up to x
      // downloads to run at once). See https://pub.dev/packages/queue
      final servedMedia = await clone(media, conversionArgs);
      yield servedMedia;
    }
  }

  // Clones all media published to the collection. If [after] is specified,
  // only media published after the specified date are cloned.
  //
  // Media will be cloned in chronological order (in the same order they were
  // originally published at the source).
  Stream<ServedMedia> cloneCollection(ClonerConfiguration configuration,
      [DateTime after]) async* {
    // Because reverseChronologicalMedia returns newest media first, we must
    // first get the list of all media and reverse it before cloning any media.
    var stream = _downloader.reverseChronologicalMedia(
        configuration.sourceCollection, after);
    final mediaList = (await stream.toList()).reversed;
    if (mediaList.isEmpty) {
      print(
          'No media found after $after for ${configuration.sourceCollection}');
    } else {
      yield* _cloneAll(mediaList, configuration.mediaConversionArgs);
    }
  }

  Future<ServedMedia> cloneMostRecentMedia(
      ClonerConfiguration configuration) async {
    final media =
        await _downloader.mostRecentMedia(configuration.sourceCollection);
    return clone(media, configuration.mediaConversionArgs);
  }

  void close() {
    _downloader.close();
    _mediaConverter.close();
    _uploader.close();
    _feedManager.close();
  }
}
