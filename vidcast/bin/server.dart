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
final feedsBaseDirectoryPath = '$home/web/feeds/';

// Set to true to expose the site on external service localhost.run,
// false to make available at localhost:8080 and videate.org (the latter only
// works when port forwarding is set up and dns points to correct IP)
const expose = true;

// Writes the specified feed data as rss to the specified response object
serveFeed(Map feedData, String hostname, HttpResponse response) {
  final feed =
      FeedGenerator.generate(feedData, hostname, videosBaseDirectoryPath);
  response.headers.contentType =
      new ContentType("application", "xml", charset: "utf-8");
  response.write(feed.toString());
}

final videateHost = 'http://videate.org';
final localHost = 'http://localhost:8080';
Future main() async {
  final hostname =
      expose ? (await LocalhostExposer.expose()).hostname : localHost;

  // Find the home directory
  if (!Platform.isMacOS) {
    throw "Unsupported OS";
  }

  // Print out the url to each valid feed
  final feedsBaseDirectory = Directory(feedsBaseDirectoryPath);
  final feedFiles = feedsBaseDirectory
      .listSync(recursive: false)
      .where((file) => path.extension(file.path) == '.json');
  final videosBaseDirectory = Directory(videosBaseDirectoryPath);
  final videoFolders = videosBaseDirectory
      .listSync(recursive: false)
      .where((entity) => entity is Directory);
  final validFeedNames = [...feedFiles, ...videoFolders]
      .map((entity) => path.basenameWithoutExtension(entity.uri.path))
      .toSet();
  validFeedNames
      .forEach((feedName) => print('$feedName Feed: $hostname/$feedName'));

  // Make all media under /web/videos accessible.
  var staticFiles = VirtualDirectory(videosBaseDirectoryPath);
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
    } else if (request.uri.hasQuery) {
      final creator = request.uri.queryParameters['creator'];
      request.response.write('Your \$1 tip has been sent to $creator');
      request.response.close();
    } else if (path.extension(request.uri.path) == '') {
      // feed request (i.e. a request without a file extension)
      final name = path.basenameWithoutExtension(request.uri.path);

      // First look for an explicit json metadata file with the requested name
      final metadataFile = File('$feedsBaseDirectoryPath$name.json');
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
          request.response.write(
              'Failed to generate rss feed for $name. No such feed or folder found.');
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
