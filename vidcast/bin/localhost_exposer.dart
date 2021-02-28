// Makes localhost available to the wider internet using http://localhost.run.
import 'dart:convert';
import 'dart:io';

class ExposerProcess {
  final String hostname;
  final Process process;

  ExposerProcess(this.hostname, this.process);
}

// Starts a process to expose localhost at the url this Future completes with
Future<ExposerProcess> expose() async {
  final process = await Process.start(
      'ssh', ['-R', '80:localhost:8080', 'ssh.localhost.run']);

  // Get the resulting base url for this run (it changes every run).
  // Output will be sent to the first line of stdout output from the process,
  // which then continues to run.
  final output = await process.stdout.transform(utf8.decoder).first;

  // expected format for 'output':
  // old:  "Connect to http://mikem-abcd.localhost.run or https://mikem-abcd.localhost.run"
  // new: "mikem-2e47e711.localhost.run tunneled with tls termination"
  // old: RegExp exp = new RegExp(
  //    r"Connect to (http://.*.localhost.run)"); // or (https://.*.localhost.run)");
  RegExp exp =
      new RegExp(r"(.*\.localhost\.run)"); // or (https://.*.localhost.run)");
  final match = exp.firstMatch(output);
  var hostname;
  if (match != null) {
    hostname = match[1];
  }
  if (hostname == null) {
    throw ('Error getting hostname from localhost.run. Output: $output');
  }

  // Handle crashes in the exposer process by killing the server
  process.exitCode.then((exitCode) {
    throw ('Exposer process quit unexpectedly. This server is no longer exposed at $hostname. Exit code: $exitCode');
  });

  return ExposerProcess(hostname, process);
}
