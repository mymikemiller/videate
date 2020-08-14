import 'dart:io';
import 'package:http/http.dart';
import 'package:path/path.dart';

mixin Rsync {
  String get endpointUrl;

  // We use dependency injection to allow for mocking the client when pulling,
  // and the rsync command when pushing
  Client get rsyncClient;
  dynamic get rsyncProcessRunner;

  Future<void> push(File file, String destinationPath) async {
    // rsync -e "ssh -i ~/.ssh/cdn77_id_rsa" /path/to/source.txt
    // user_amhl64ul@push-24.cdn77.com:/www/path/to/destination.txt
    final output = await rsyncProcessRunner('rsync', [
      '-e',
      'ssh -i ~/.ssh/cdn77_id_rsa',
      file.path,
      'user_amhl64ul@push-24.cdn77.com:/www/$destinationPath',
    ]);

    if (output.stderr.isNotEmpty) {
      if (output.stderr.toString().contains('connection unexpectedly closed') &&
          output.stderr
              .toString()
              .contains('error in rsync protocol data stream')) {
        final dir = dirname(destinationPath);
        print(
            'rsync error may imply a missing directory structure at the destination. Try creating the "www/$dir" directory.');
      }
      throw 'process rsync error: ${output.stderr}';
    }
  }

  Future<String> pull(String path) async {
    return rsyncClient.read('$endpointUrl/$path');
  }
}
