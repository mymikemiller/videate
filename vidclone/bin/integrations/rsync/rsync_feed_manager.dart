import 'package:file/local.dart';
import 'package:http/http.dart';
import 'package:vidlib/vidlib.dart' hide Platform;
import '../../feed_manager.dart';
import 'rsync.dart';
import 'package:path/path.dart' as p;

// Base class for FeedManagers that use the rsync command to persist feeds.
abstract class RsyncFeedManager extends FeedManager with Rsync {
  RsyncFeedManager(this.feedDirectoryPath);

  // The path to the feed directory where the feed files are located. This path
  // appears directly after the endpoint url. For example, for the file hosted
  // at https://1928422091.rsc.cdn77.org/feeds/myfeed.json, the
  // feedDirectoryPath is 'feeds/'
  final String feedDirectoryPath;

  // The feed file's name. For example, for the file hosted at
  // https://1928422091.rsc.cdn77.org/feeds/myfeed.json, the feedFileName is
  // myfeed.json
  String feedFileName;

  String get feedFilePath => p.join(feedDirectoryPath, feedFileName);

  @override
  void configure(ClonerConfiguration configuration) {
    super.configure(configuration);
    feedFileName = configuration.feedName;
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
      json = await pull(feedFilePath);
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
    final tempDir = fs.systemTempDirectory.createTempSync();
    final file = fs.file('${tempDir.path}/$feedFileName');
    file.createSync();

    final json = feed.toJson();
    file.writeAsStringSync(json);

    await push(file, feedFilePath);

    tempDir.deleteSync(recursive: true);
  }
}
