import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mime/mime.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..post('/upload/', _uploadHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request, String message) {
  return Response.ok('$message\n');
}

Future<Response> _uploadHandler(Request request) async {
  List<int> dataBytes = [];

  await for (var data in request.read()) {
    dataBytes.addAll(data);
  }

  // String boundary = request.headers.contentType.parameters['boundary'];
  final String contentTypeValue = request.headers['content-type']!;
  MediaType contentType = MediaType.parse(contentTypeValue);
  final boundary = contentType.parameters['boundary']!;
  final transformer = MimeMultipartTransformer(boundary);
  final uploadDirectory = './uploads';

  final bodyStream = Stream.fromIterable([dataBytes]);
  final parts = await transformer.bind(bodyStream).toList();

  for (var part in parts) {
    print(part.headers);
    final contentDisposition = part.headers['content-disposition'];
    final filename =
        RegExp(r'filename="([^"]*)"').firstMatch(contentDisposition!)?.group(1);
    final content = await part.toList();

    if (!Directory(uploadDirectory).existsSync()) {
      await Directory(uploadDirectory).create();
    }

    await File('$uploadDirectory/$filename').writeAsBytes(content[0]);
  }

  return Response.ok('Upload complete');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final _handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(_handler, ip, port);
  print('Server listening on port ${server.port}');
}
