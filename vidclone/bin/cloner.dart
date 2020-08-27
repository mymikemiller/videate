import 'dart:io';
import 'package:vidlib/vidlib.dart';
import 'package:file/memory.dart';
import 'downloader.dart';
import 'feed_manager.dart';
import 'uploader.dart';
import 'package:console/console.dart';

// A fake file system that allows us to interact with downloaded data as though
// it were a file on an actual file system, but it's only ever stored in
// memory.
final memoryFileSystem = MemoryFileSystem();

class Cloner {
  final Downloader _downloader;
  final Uploader _uploader;
  final FeedManager _feedManager;

  Cloner(this._downloader, this._uploader, this._feedManager);

  // Clones the [Media] by downloading it from the source, uploading it to the
  // destination, then updating a feed.
  //
  // Downloading and uploading will be performed according to this Cloner's
  // Downloader and Upoader behavior.
  //
  // Media that already exist at the uploader's destination will not be
  // cloned. Instead, a [ServedMedia] will be immediately returned.
  Future<ServedMedia> clone(Media media) async {
    final mediaDebugName =
        '${media.source.platform.id} Media ${media.source.id}';
    Console.init();

    // Existence Check
    print('=== Clone: Checking if already cloned: $mediaDebugName ===');
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
      var progressBar = ProgressBar();
      final downloadResult = await time(_downloader.download, [
        media,
        (double progress) {
          updateProgressBar(progressBar, progress);
        }
      ]);
      final fsMedia = await downloadResult.returnValue;
      print('=== ⏲ ${downloadResult.time} ⏲ ===');

      // Upload
      print('=== Clone: Upload $mediaDebugName ===');
      final uploadResult = await time(_uploader.upload, [fsMedia]);
      servedMedia = await uploadResult.returnValue;
      print('=== ⏲ ${uploadResult.time} ⏲ ===');

      print('served media: ${servedMedia.uri}');
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
  Stream<ServedMedia> cloneCollection(SourceCollection sourceCollection,
      [DateTime after]) async* {
    // Because reverseChronologicalMedia returns newest media first, we must
    // first get the list of all media and reverse it before cloning any media.
    var stream = _downloader.reverseChronologicalMedia(sourceCollection, after);
    final mediaList = (await stream.toList()).reversed;
    if (mediaList.isEmpty) {
      print('No media found after $after for ${sourceCollection}');
    } else {
      await for (var servedMedia in _cloneAll(mediaList)) {
        yield servedMedia;
      }
      // TODO: switch to this? yield* _cloneAll(mediaList);
    }
  }

  void updateProgressBar(ProgressBar progressBar, double progress) {
    final progressInt = (progress * 100).round();
    try {
      progressBar.update(progressInt);
    } on StdoutException catch (e) {
      if (e.message == 'Could not get terminal size') {
        print(
            'If using VSCode, make sure you\'re using the Integrated Terminal,'
            ' as the Debug Console does not support cursor positioning '
            'necessary to display the progress bar. Set `"console": '
            '"terminal"` in launch.json.');
      }
    }
  }

  Future<ServedMedia> cloneMostRecentMedia(
      SourceCollection sourceCollection) async {
    final media = await _downloader.mostRecentMedia(sourceCollection);
    return clone(media);
  }

  void close() {
    _downloader.close();
    _uploader.close();
    _feedManager.close();
  }
}
