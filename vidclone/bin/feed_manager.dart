import 'package:vidlib/vidlib.dart';
import 'cloner_task.dart';

abstract class FeedManager extends ClonerTask {
  // An id unique to this feed manager, e.g. "json_file".
  String get id;

  // The feed's name, for display purposes
  String get feedName;

  // Initialize this feed with the contents from the source by calling
  // `populate()`. Write its contents back to the source with write(). Thus,
  // the feed may be out of sync with the source until write() is called.
  Feed _feed;
  Feed get feed {
    if (_feed == null) {
      throw StateError(
          'Null feed. Set manually or call populate() before accessing.');
    }
    return _feed;
  }

  set feed(Feed feed) => _feed = feed;

  // Populate the feed, overwriting everything with data from the source.
  // Returns `false` and makes no modifications if the feed was not found at
  // the source.
  Future<bool> populate();

  // Writes the feed to the source, creating if necessary or overwriting the
  // existing feed at the source.
  Future<void> write();

  Future<void> add(ServedMedia media, {bool write = true}) async {
    feed = feed.withMediaAdded(media);
    if (write) {
      return this.write();
    }
  }

  Future<void> addAll(List<ServedMedia> mediaList, {bool write = true}) async {
    feed = feed.withAllMediaAdded(mediaList);
    if (write) {
      return this.write();
    }
  }
}
