import 'dart:io';

import 'package:file/local.dart';
import 'package:http/http.dart';
import 'package:vidlib/vidlib.dart' hide Platform;
import '../../feed_manager.dart';
import 'rsync.dart';
import 'package:path/path.dart';

// Base class for FeedManagers that use the rsync command to persist feeds.
abstract class RsyncFeedManager extends FeedManager with Rsync {
  RsyncFeedManager(this.path);

  // The path to the feed after the endpoint url. For the file hosted at
  // https://1928422091.rsc.cdn77.org/feeds/myfeed.json, for example, use
  // 'feeds/myfeed.json'
  final String path;

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
      json = await pull(path);
    } on ClientException {
      // 404 errors end up here
      return false;
    }

    feed = Feed.fromJson(json);
    return true;
  }

  @override
  Future<void> write() async {
    final fileName = basename(path);

    // Create a temporary file for rsync to upload
    final fs = LocalFileSystem();
    final tempDir = fs.systemTempDirectory.createTempSync();
    final file = fs.file('${tempDir.path}/$fileName');
    file.createSync();

    final json = feed.toJson();
    file.writeAsStringSync(json);

    await push(file, path);

    tempDir.deleteSync(recursive: true);
  }
}
