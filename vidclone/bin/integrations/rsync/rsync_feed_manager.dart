import 'package:file/local.dart';
import 'package:http/http.dart';
import 'package:vidlib/vidlib.dart' hide Platform;
import '../../feed_manager.dart';
import 'rsync.dart';
import 'package:path/path.dart';

// Base class for FeedManagers that use the rsync command to persist feeds.
abstract class RsyncFeedManager extends FeedManager with Rsync {
  RsyncFeedManager();

  // The path to the feed. This path appears directly after the endpoint url.
  // For example, for the file hosted at
  // https://1928422091.rsc.cdn77.org/feeds/myfeed.json, the feedPath is
  // 'feeds/myfeed.json'
  String feedPath;

  @override
  String get feedName => basename(feedPath);

  @override
  void configure(ClonerTaskArgs feedManagerArgs) {
    feedPath = feedManagerArgs.get('path');
  }

  // Use the FeedManager's client for rsync requests
  @override
  Client get rsyncClient => client;

  // Use the FeedManager's processRunner to run the rsync process
  @override
  dynamic get rsyncProcessRunner => processRunner;

  @override
  Future<bool> populate() async {
    String json;
    try {
      json = await pull(feedPath);
    } on ClientException {
      // 404 errors end up here
      return false;
    }

    feed = Feed.fromJson(json);
    return true;
  }

  @override
  Future<void> write() async {
    // Create a temporary file for rsync to upload
    final fs = LocalFileSystem();
    final tempDir = createTempDirectory(fs);
    final file = fs.file('${tempDir.path}/$feedPath');
    file.createSync(recursive: true);

    final json = feed.toJson();
    file.writeAsStringSync(json);

    await push(file, feedPath);

    tempDir.deleteSync(recursive: true);
  }
}
