import 'dart:io';
import 'package:file/local.dart';
import 'package:vidlib/vidlib.dart';
import 'package:file/memory.dart';
import 'downloader.dart';
import 'feed_manager.dart';
import 'media_converter.dart';
import 'uploader.dart';

// A fake file system that allows us to interact with downloaded data as though
// it were a file on an actual file system, but it's only ever stored in
// memory.
final memoryFileSystem = MemoryFileSystem();

class Cloner {
  final FeedManager feedManager;
  final Downloader downloader;
  final MediaConverter mediaConverter;
  final Uploader uploader;

  Cloner(this.feedManager, this.downloader, this.mediaConverter, this.uploader);

  // Clones the [Media] by downloading it from the source, converting the file
  // if necessary, uploading it to the destination, then updating a feed.
  //
  // Downloading and uploading will be performed according to this Cloner's
  // Downloader and Upoader behavior.
  //
  // Media that already exist at the uploader's destination will not be cloned.
  // Instead, a [ServedMedia] will be immediately returned.
  Future<ServedMedia> clone(Media media) async {
    print('=== Clone: ${media.source.id} (${media.title})');

    // Existence Check
    print('=== FeedManager (${feedManager.id}) Checking if already cloned ===');
    final existenceCheckResult =
        await time(uploader.getExistingServedMedia, [media]);

    var servedMedia;

    // Short-circuit downloading and uploading if the destination exists
    if (existenceCheckResult.returnValue != null) {
      print('Destination exists. Skipping Download, Convert and Upload steps.');
      print('=== ⏲  ${existenceCheckResult.time} ⏲  ===');
      servedMedia = existenceCheckResult.returnValue;
    } else {
      print('Destination does not exist. Performing full clone.');
      print('=== ⏲  ${existenceCheckResult.time} ⏲  ===');

      // Download
      print('=== Download (${downloader.platform.id}) ===');
      final downloadResult =
          await time(downloader.download, [media], {}, 'callback');
      final downloadedMedia = await downloadResult.returnValue;
      print('=== ⏲  ${downloadResult.time} ⏲  ===');

      // Convert
      print('=== Convert (${mediaConverter.id}) ===');
      final conversionResult =
          await time(mediaConverter.convert, [downloadedMedia], {}, 'callback');
      final convertedMedia = await conversionResult.returnValue;
      final initialSize = (downloadedMedia as MediaFile).file.lengthSync();
      final convertedSize = (convertedMedia as MediaFile).file.lengthSync();
      final reduction = ((initialSize - convertedSize) / initialSize) * 100;
      print('Reduced file size by ${reduction.round()}%');
      print('=== ⏲  ${conversionResult.time} ⏲  ===');

      // Upload
      print('=== Upload (${uploader.id}) ===');
      final uploadResult =
          await time(uploader.upload, [convertedMedia], {}, 'callback');
      servedMedia = await uploadResult.returnValue;
      print('=== ⏲  ${uploadResult.time} ⏲  ===');
      print('served media:${servedMedia.uri}');
    }

    // Update the feed to include the new media
    print('=== FeedManager (${feedManager.id}) Add to Feed ===');
    final feedAddResult = await time(feedManager.add, [servedMedia]);
    print('=== ⏲  ${feedAddResult.time} ⏲  ===');

    return servedMedia;
  }

  // This function can be parallelized, but caution should be taken to ensure
  // upload order is maintained if desired, and blocking doesn't occur due to
  // too many simultaneous downloads/uploads.
  Stream<ServedMedia> _cloneAll(Iterable<Media> media) async* {
    for (var media in media) {
      // This can be parallelized, but for simplicity's sake we're awaiting
      // each one here TODO: parallelize this (a queue allowing up to x
      // downloads to run at once). See https://pub.dev/packages/queue
      final servedMedia = await clone(media);
      yield servedMedia;
    }
  }

  // Clones all media published to the collection. If [after] is specified,
  // only media published after the specified date are cloned.
  //
  // Media will be cloned in chronological order (in the same order they were
  // originally published at the source).
  Stream<ServedMedia> cloneCollection([DateTime after]) async* {
    // Because reverseChronologicalMedia returns newest media first, we must
    // first get the list of all media and reverse it before cloning any media.
    var stream = downloader.reverseChronologicalMedia(after);
    final mediaList = (await stream.toList()).reversed;
    if (mediaList.isEmpty) {
      print('No media found after $after');
    } else {
      yield* _cloneAll(mediaList);
    }
  }

  Future<ServedMedia> cloneMostRecentMedia() async {
    final media = await downloader.mostRecentMedia();
    return clone(media);
  }

  void close() {
    downloader.close();
    mediaConverter.close();
    uploader.close();
    feedManager.close();
  }
}
