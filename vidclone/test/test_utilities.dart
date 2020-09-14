import 'dart:io';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';

class FakeProcess extends Fake implements Process {
  @override
  Stream<List<int>> get stderr => Stream.fromIterable([]);

  @override
  Future<int> get exitCode => Future.value(0);
}

final noopProcessRun =
    (String executable, List<String> arguments) => ProcessResult(0, 0, '', '');

final noopProcessStart =
    (String executable, List<String> arguments) => Future.value(FakeProcess());

final failureMockClient = MockClient((request) async {
  return Response('', 404);
});
