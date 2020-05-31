import 'dart:convert';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:vidlib/src/models/served_video.dart';
import 'package:vidlib/vidlib.dart';
import '../../feed_manager.dart';
import 'package:path/path.dart';

class JsonFileFeedManager extends FeedManager {
  @override
  String get id => 'json_file';

  final String jsonFilePath;
  final FileSystem fileSystem;

  // This feed is initialized with the contents of the json file on
  // initialization, and its contents are written to the file when write() is
  // called. Therefore, the feed may be out if sync with the json file until
  // write() is called.
  Feed _feed;

  JsonFileFeedManager._(this.jsonFilePath,
      {this.fileSystem = const LocalFileSystem()});

  static Future<JsonFileFeedManager> open(String jsonFilePath,
      {FileSystem fileSystem = const LocalFileSystem()}) async {
    final file = fileSystem.file(jsonFilePath);
    if (!file.existsSync()) {
      throw 'Can\t open nonexistent json file at $jsonFilePath. Try using create() or createOrOpen().';
    }
    final manager = JsonFileFeedManager._(jsonFilePath, fileSystem: fileSystem);

    final json = file.readAsStringSync();
    if (json.isEmpty) {
      // Create an empty feed
      manager._feed = Examples.emptyFeed.rebuild((b) => b
        ..title = basenameWithoutExtension(jsonFilePath)
        ..subtitle = '${basenameWithoutExtension(jsonFilePath)} feed)');
    } else {
      // Load the requested feed
      final feedData = jsonDecode(json);
      manager._feed = jsonSerializers.deserialize(feedData) as Feed;
    }
    return manager;
  }

  static Future<JsonFileFeedManager> create(String jsonFilePath,
      {FileSystem fileSystem = const LocalFileSystem()}) async {
    final file = fileSystem.file(jsonFilePath);
    if (file.existsSync()) {
      throw 'Json file already exists at $jsonFilePath. Try using open() or createOrOpen()';
    }
    file.createSync();
    final feed = Examples.emptyFeed.rebuild((b) => b
      ..title = basenameWithoutExtension(jsonFilePath)
      ..subtitle = '${basenameWithoutExtension(jsonFilePath)} feed');

    final manager = JsonFileFeedManager._(jsonFilePath, fileSystem: fileSystem);
    manager._feed = feed;

    // Write the new file to disk.
    await manager.write();
    return manager;
  }

  static Future<JsonFileFeedManager> createOrOpen(String jsonFilePath,
      {FileSystem fileSystem = const LocalFileSystem()}) async {
    final file = fileSystem.file(jsonFilePath);

    if (file.existsSync()) {
      return open(jsonFilePath, fileSystem: fileSystem);
    } else {
      return create(jsonFilePath, fileSystem: fileSystem);
    }
  }

  @override
  Future<void> add(ServedVideo video, {bool write = true}) async {
    _feed = feed.withVideoAdded(video);
    if (write) {
      return this.write();
    }
  }

  @override
  Future<void> addAll(List<ServedVideo> videos, {bool write = true}) async {
    _feed = feed.withAllVideosAdded(videos);
    if (write) {
      return this.write();
    }
  }

  @override
  Feed get feed => _feed;

  Future<void> write() {
    final newJson = jsonSerializers.serialize(feed);

    final file = fileSystem.file(jsonFilePath);
    if (!file.existsSync()) {
      throw 'Json file write operation failed: file does not exist at $jsonFilePath';
    }

    // Rewrite the entire file with the new feed, which now contains everything
    return file.writeAsString(jsonEncode(newJson));
  }
}
