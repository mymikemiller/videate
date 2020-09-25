import 'package:file/file.dart';
import 'package:vidlib/vidlib.dart';
import '../../feed_manager.dart';

class JsonFileFeedManager extends FeedManager {
  @override
  String get id => 'json_file';

  Directory baseDirectory;
  String jsonFileName;

  JsonFileFeedManager(this.baseDirectory);

  @override
  void configure(ClonerConfiguration configuration) {
    jsonFileName = '${configuration.feedName}.json';
  }

  @override
  Future<bool> populate() async {
    final file = baseDirectory.childFile(jsonFileName);
    if (!file.existsSync()) {
      return false;
    }

    final json = file.readAsStringSync();
    feed = Feed.fromJson(json);
    return true;
  }

  @override
  Future<void> write() async {
    final file = baseDirectory.childFile(jsonFileName);

    // Create the file if necessary (this is a no-op if the file already
    // exists)
    file.createSync(recursive: true);

    // Rewrite the entire file with the feed
    final json = feed.toJson();
    return file.writeAsString(json);
  }
}
