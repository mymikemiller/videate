import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:vidlib/vidlib.dart';
import '../../feed_manager.dart';
import 'package:path/path.dart';

class JsonFileFeedManager extends FeedManager {
  FileSystem fileSystem = LocalFileSystem();

  @override
  String get id => 'json_file';

  String path;

  @override
  String get feedName => basenameWithoutExtension(path);

  JsonFileFeedManager();

  @override
  void configure(ClonerTaskArgs feedManagerArgs) {
    path = feedManagerArgs.get('path');
  }

  @override
  Future<bool> populate() async {
    final file = fileSystem.file(path);
    if (!file.existsSync()) {
      return false;
    }

    final json = file.readAsStringSync();
    feed = Feed.fromJson(json);
    return true;
  }

  @override
  Future<void> write() async {
    final file = fileSystem.file(path);

    // Create the file if necessary (this is a no-op if the file already
    // exists)
    file.createSync(recursive: true);

    // Rewrite the entire file with the feed
    final json = feed.toJson();
    return file.writeAsString(json);
  }
}
