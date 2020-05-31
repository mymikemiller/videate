// Serves generated rss feeds for the content under /web
// Use the URL localhost:8080 in your browser.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:http_server/http_server.dart';
import 'package:vidlib/vidlib.dart';
import 'feed_formatters/feed_formatter.dart';
import 'localhost_exposer.dart' as LocalhostExposer;
import 'package:path/path.dart' as path;
import 'feed_formatters/rss_2_0_feed_formatter.dart';
import 'package:dotenv/dotenv.dart' show load, env;

final home = Platform.environment['HOME'];
final videosBaseDirectoryPath = '$home/web/videos/';
final feedsBaseDirectoryPath = '$home/web/feeds/';

// Writes the specified feed data as rss to the specified response object
serve(Feed feed, FeedFormatter feedFormatter, HttpResponse response) {
  final formattedFeed = feedFormatter.format(feed);
  response.headers.contentType =
      new ContentType("application", "xml", charset: "utf-8");
  response.write(formattedFeed.toString());
}

Future main(List<String> args) async {
  // Load environment variables from local .env file
  load();
  final vidcastBaseUrl = getEnvVar('VIDCAST_BASE_URL', env);

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
  final feedFormatter = RSS_2_0_FeedFormatter(baseUrl);

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

      // We expect to find a json feed file with the requested name
      final file = File('$feedsBaseDirectoryPath/$name.json');
      if (file.existsSync()) {
        final json = await file.readAsString();
        final data = jsonDecode(json);
        final feed = Feed.fromJson(data);
        serve(feed, feedFormatter, request.response);
      } else {
        request.response.write('No feed with the name "$name" found.');
      }

      request.response.close();
    } else {
      // Video file request
      staticFiles.serveRequest(request);
    }
  }
}
