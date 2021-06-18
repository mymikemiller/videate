// Run locally, this will serve all videos under $home/web/media Use the URL
// localhost:8080 in your browser. Code here used to generate and serve rss
// feeds, but that functaionality has moved to the Internet Computer under the
// "credits" project
import 'dart:async';
import 'dart:convert';
import 'package:vidlib/vidlib.dart' hide Platform;
import 'dart:io';
import 'package:args/args.dart';
import 'package:http_server/http_server.dart';
import 'feed_formatters/feed_formatter.dart';
import 'localhost_exposer.dart' as LocalhostExposer;
import 'package:path/path.dart' as path;
import 'feed_formatters/rss_2_0_feed_formatter.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:path/path.dart' as p;

final home = Platform.environment['HOME'];
final mediaBaseDirectoryPath = '$home/web/media';
final feedsBaseDirectoryPath = '$home/web/feeds';

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
  final cdn77VidtechBaseUrl = getEnvVar('CDN77_VIDTECH_BASE_URL', env);
  final cdn77BaseUrl = getEnvVar('CDN77_BASE_URL', env);

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

  final UriTransformer localFileUriTransformer = (Uri input) => Uri.parse(
      input.toString().replaceFirst('file://$mediaBaseDirectoryPath', baseUrl));
  final UriTransformer cdn77UriTransformer = (Uri input) => Uri.parse(
      input.toString().replaceFirst(cdn77BaseUrl, cdn77VidtechBaseUrl));

  // final feedFormatter =
  //     RSS_2_0_FeedFormatter([localFileUriTransformer, cdn77UriTransformer]);

  // Print out the url to each valid feed
  final feedsBaseDirectory = Directory(feedsBaseDirectoryPath);
  final feedFiles = feedsBaseDirectory
      .listSync(recursive: false)
      .where((file) => path.extension(file.path) == '.json');
  final mediaBaseDirectory = Directory(mediaBaseDirectoryPath);
  final mediaFolders = mediaBaseDirectory
      .listSync(recursive: false)
      .where((entity) => entity is Directory);
  final validFeedNames = [...feedFiles, ...mediaFolders]
      .map((entity) => path.basenameWithoutExtension(entity.uri.path))
      .toSet();
  validFeedNames
      .forEach((feedName) => print('$feedName Feed: $baseUrl/$feedName'));

  // Make all media under /web/media accessible.
  var staticFiles = VirtualDirectory(mediaBaseDirectoryPath);
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
      throw 'Received non-file request from server. Rss feed generation has moved to the IC';
      // // feed request (i.e. a request without a file extension)
      // final name = path.basenameWithoutExtension(request.uri.path);

      // // We expect to find a json feed file with the requested name
      // final file = File('$feedsBaseDirectoryPath/$name.json');
      // if (file.existsSync()) {
      //   final json = await file.readAsString();
      //   final feed = Feed.fromJson(json);
      //   serve(feed, feedFormatter, request.response);
      // } else {
      //   request.response.write('No feed with the name "$name" found.');
      // }

      // request.response.close();
    } else {
      // Video file request
      staticFiles.serveRequest(request);
    }
  }
}
