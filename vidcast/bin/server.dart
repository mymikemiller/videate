// Serves generated rss feeds for the content under /web
// Use the URL localhost:8080 in your browser.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:http_server/http_server.dart';
import 'localhost_exposer.dart' as LocalhostExposer;
import 'package:path/path.dart' as path;
import 'feed_generator.dart';
import 'metadata_generator.dart';
import 'package:dotenv/dotenv.dart' show load, env;

final home = Platform.environment['HOME'];
final videosBaseDirectoryPath = '$home/web/videos/';
final feedsBaseDirectoryPath = '$home/web/feeds/';

// Writes the specified feed data as rss to the specified response object
serveFeed(Map feedData, String baseUrl, HttpResponse response) {
  final feed =
      FeedGenerator.generate(feedData, baseUrl, videosBaseDirectoryPath);
  response.headers.contentType =
      new ContentType("application", "xml", charset: "utf-8");
  response.write(feed.toString());
}

Future main(List<String> args) async {
  // Load environment variables from local .env file
  load();
  final vidcastBaseUrl = '${env['VIDCAST_BASE_URL']}';

  // Parse command line args
  var parser = ArgParser()
    ..addFlag('expose-localhost', abbr: 'e', defaultsTo: false);
  final argResults = parser.parse(args);
  final exposeLocalhost = argResults['expose-localhost'];

  // If the expose-localhost arg is set, we use an extenal service
  // (localhost.run) to expose the server to the oustside world (e.g. for
  // testing on a smartphone that doesn't have access to the machine's
  // localhost).
  final baseUrl = exposeLocalhost
      ? (await LocalhostExposer.expose()).hostname
      : vidcastBaseUrl;

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
      .forEach((feedName) => print('$feedName Feed: $baseUrl/$feedName'));

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
        serveFeed(feedData, baseUrl, request.response);
      } else {
        // Look for a folder of video files with the requested name
        final directory = Directory(videosBaseDirectoryPath + name);
        if (directory.existsSync()) {
          final feedData = await MetadataGenerator.fromFolder(
              directory, videosBaseDirectoryPath);
          serveFeed(feedData, baseUrl, request.response);
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
