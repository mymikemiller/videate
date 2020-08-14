import 'dart:io';

import 'package:http/http.dart';
import 'package:http/testing.dart';

final noopProcess =
    (String executable, List<String> arguments) => ProcessResult(0, 0, '', '');

final failureMockClient = MockClient((request) async {
  return Response('', 404);
});
