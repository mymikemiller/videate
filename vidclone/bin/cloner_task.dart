import 'dart:io';
import 'package:http/http.dart';
import 'package:vidlib/vidlib.dart';

abstract class ClonerTask {
  Client client;
  dynamic processRunner;
  dynamic processStarter;

  ClonerTask() {
    client = Client();
    processRunner = Process.run;
    processStarter = Process.start;
  }

  void configure(ClonerTaskArgs args) {
    // No configuration by default
  }

  // Perform any cleanup. This ClonerTask should no longer be used after this
  // is called.
  void close() {
    client.close();
  }
}
