import 'dart:io';
import 'package:http/http.dart';

abstract class ClonerTask {
  Client client;
  dynamic processRunner;

  ClonerTask() {
    client = Client();
    processRunner = Process.run;
  }

  // Perform any cleanup. This ClonerTask should no longer be used after this
  // is called.
  void close() {
    client.close();
  }
}
