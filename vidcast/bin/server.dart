// Serves generated rss feeds for the content under /web
// Use the URL localhost:8080 in your browser.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http_server/http_server.dart';
import 'package:xml/xml.dart';
import 'localhost_exposer.dart' as LocalhostExposer;
import 'package:path/path.dart' as path;
import 'feed_generator.dart';
import 'metadata_generator.dart';

XmlDocument demoFeed;

// Set to true to expose the site on external service localhost.run,
// false to make available at localhost:8080 and videate.org (the latter only
// works when port forwarding is set up and dns points to correct IP)
const expose = false;

Future main() async {
  final hostname = expose
      ? (await LocalhostExposer.expose()).hostname
      : 'http://videate.org';

  // Find the home directory
  if (!Platform.isMacOS) {
    throw "Unsupported OS";
  }
  final home = Platform.environment['HOME'];

  // Print out the url to each valid feed
  print('Demo Feed: $hostname/demo.xml');
  final videosBaseDirectoryPath = '$home/web/videos/';
  final videosBaseDirectory = Directory(videosBaseDirectoryPath);
  for (FileSystemEntity entity
      in videosBaseDirectory.listSync(recursive: false)) {
    if (entity is Directory) {
      final folderName = path.basename(entity.uri.path);
      print('$folderName Feed: $hostname/$folderName.xml');
    }
  }

  // Generate the demo feed from the metadata in the specified json file
  final demoFile = File('$home/web/feeds/demo.json');
  final demoJson = await demoFile.readAsString();
  final demoFeedData = jsonDecode(demoJson);
  demoFeed = FeedGenerator.generate(hostname, demoFeedData, '$home/web/videos');

  // Make all media under /web/videos accessible.
  var staticFiles = VirtualDirectory('$home/web/videos/');
  staticFiles.allowDirectoryListing = true;
  staticFiles.directoryHandler = (dir, request) {
    var indexUri = Uri.file(dir.path).resolve('index.html');
    staticFiles.serveFile(File(indexUri.toFilePath()), request);
  };

  // Initialize http listener
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Listening on port 8080');
  await for (var request in server) {
    print("request.uri.path: " + request.uri.path);

    if (request.uri.path == '/') {
      var indexUri = Uri.file('/index.html');
      staticFiles.serveFile(File(indexUri.toFilePath()), request);
    } else if (request.uri.path == '/demo.xml') {
      // Demo request. Return hardcoded demo feed.
      request.response.headers.contentType =
          new ContentType("application", "xml", charset: "utf-8");
      request.response.write(demoFeed.toString());
      request.response.close();
    } else if (request.uri.path.endsWith('.xml')) {
      // Feed request. Generate a feed for the folder at the requested path.
      final folderName = path.basenameWithoutExtension(request.uri.path);
      final directory = Directory(videosBaseDirectoryPath + folderName);
      if (directory.existsSync()) {
        final feedData = await MetadataGenerator.fromFolder(
            directory, videosBaseDirectoryPath);
        final feed =
            FeedGenerator.generate(hostname, feedData, videosBaseDirectoryPath);
        request.response.write(feed.toString());
      } else {
        request.response
            .write('Failed to generate for $folderName. No such folder found.');
      }
      request.response.close();
    } else {
      // File request
      staticFiles.serveRequest(request);
    }
  }
}
