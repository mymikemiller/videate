import 'dart:io';
import 'package:file/file.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:vidlib/vidlib.dart';

mixin Rsync {
  String get endpointUrl;

  // We use dependency injection to allow for mocking the client when pulling,
  // and the rsync command when pushing
  Client get rsyncClient;
  dynamic get rsyncProcessRunner;

  Future<void> push(File file, String destinationPath) async {
    file = await ensureLocal(file);

    // rsync -e "ssh -i ~/.ssh/cdn77_id_rsa" "/path/to/source.txt"
    // user_amhl64ul@push-24.cdn77.com:/www/path/to/destination.txt
    final output = await rsyncProcessRunner('rsync', [
      '--protect-args',
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
      // todo: fix this when there's not a folder for the feed: rsync error may imply a missing directory structure at the destination. Try creating the "www/media/youtube/gamegrumps" directory.
      throw 'rsync process error: ${output.stderr}';
    }
  }

  Future<String> pull(String path) async {
    return rsyncClient.read(Uri.parse('$endpointUrl$path'));
  }
}
