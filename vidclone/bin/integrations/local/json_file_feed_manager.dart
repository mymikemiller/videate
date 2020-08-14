import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:vidlib/vidlib.dart';
import '../../feed_manager.dart';

class JsonFileFeedManager extends FeedManager {
  @override
  String get id => 'json_file';

  final String jsonFilePath;
  final FileSystem fileSystem;

  JsonFileFeedManager(this.jsonFilePath,
      {this.fileSystem = const LocalFileSystem()});

  @override
  Future<bool> populate() async {
    final file = fileSystem.file(jsonFilePath);
    if (!file.existsSync()) {
      return false;
    }

    final json = file.readAsStringSync();
    feed = Feed.fromJson(json);
    return true;
  }

  @override
  Future<void> write() async {
    final file = fileSystem.file(jsonFilePath);

    // Create the file if necessary (this is a no-op if the file already
    // exists)
    file.createSync(recursive: true);

    // Rewrite the entire file with the feed
    final json = feed.toJson();
    return file.writeAsString(json);
  }
}
