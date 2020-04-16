// Serves generated rss feeds for the content under /web
// Use the URL localhost:8080 in your browser.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http_server/http_server.dart';
import 'localhost_exposer.dart' as LocalhostExposer;
import 'package:path/path.dart' as path;
import 'feed_generator.dart';
import 'metadata_generator.dart';

final home = Platform.environment['HOME'];
final videosBaseDirectoryPath = '$home/web/videos/';

// Set to true to expose the site on external service localhost.run,
// false to make available at localhost:8080 and videate.org (the latter only
// works when port forwarding is set up and dns points to correct IP)
const expose = false;

// Writes the specified feed data as rss to the specified response object
serveFeed(Map feedData, String hostname, HttpResponse response) {
  final feed =
      FeedGenerator.generate(feedData, hostname, videosBaseDirectoryPath);
  response.headers.contentType =
      new ContentType("application", "xml", charset: "utf-8");
  response.write(feed.toString());
}

Future main() async {
  final hostname = expose
      ? (await LocalhostExposer.expose()).hostname
      : 'http://videate.org';

  // Find the home directory
  if (!Platform.isMacOS) {
    throw "Unsupported OS";
  }

  // Print out the url to each valid feed
  print('Demo Feed: $hostname/demo.xml');
  final videosBaseDirectory = Directory(videosBaseDirectoryPath);
  for (FileSystemEntity entity
      in videosBaseDirectory.listSync(recursive: false)) {
    if (entity is Directory) {
      final folderName = path.basename(entity.uri.path);
      print('$folderName Feed: $hostname/$folderName.xml');
    }
  }

  // Make all media under /web/videos accessible.
  var staticFiles = VirtualDirectory('$home/web/videos/');
  staticFiles.allowDirectoryListing = true;
  staticFiles.directoryHandler = (dir, request) {
    var indexUri = Uri.file(dir.path).resolve('index.html');
    staticFiles.serveFile(File(indexUri.toFilePath()), request);
  };

  // Initialize http listener
  final port = 8080;
  var server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Listening on port $port');
  await for (var request in server) {
    print("request.uri.path: " + request.uri.path);

    if (request.uri.path == '/') {
      var indexUri = Uri.file('/index.html');
      staticFiles.serveFile(File(indexUri.toFilePath()), request);
    } else if (request.uri.path.endsWith('.xml')) {
      // Feed request
      final name = path.basenameWithoutExtension(request.uri.path);
      
      // First look for an explicit json metadata file with the requested name
      final metadataFile = File('$home/web/feeds/$name.json');
      if (metadataFile.existsSync()) {
        final metadataJson = await metadataFile.readAsString();
        final feedData = jsonDecode(metadataJson);
        serveFeed(feedData, hostname, request.response);
      } else {
        // Look for a folder of video files with the requested name
        final directory = Directory(videosBaseDirectoryPath + name);
        if (directory.existsSync()) {
          final feedData = await MetadataGenerator.fromFolder(
              directory, videosBaseDirectoryPath);
          serveFeed(feedData, hostname, request.response);
        } else {
          request.response
              .write('Failed to generate rss feed for $name. No such feed or folder found.');
          request.response.close();
        }
      }

      request.response.close();
    } else {
      // Video file request
      staticFiles.serveRequest(request);
    }
  }
}
