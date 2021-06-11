import 'package:http/http.dart';
import 'package:vidlib/vidlib.dart' hide Platform;
import '../../uploader.dart';
import 'rsync.dart';

// Base class for uploaders that use the rsync command to upload.
abstract class RsyncUploader extends Uploader with Rsync {
  // The subfolder to store the media in inside the platform's folder. Putting
  // media in a subfolder helps when looking for media that can be deleted.
  String subfolder;

  // Use the Uploader's client for rsync requests
  @override
  Client get rsyncClient => client;

  // Use the Uploader's processRunner to run the rsync process
  @override
  dynamic get rsyncProcessRunner => processRunner;

  RsyncUploader();

  @override
  void configure(ClonerTaskArgs args) {
    subfolder = args.get('subfolder');
  }

  String getKey(Media media, [String extension = 'mp4']) {
    return 'media/${media.source.platform.id}/$subfolder/${media.source.id}.$extension';
  }

  @override
  Future<ServedMedia> uploadMedia(MediaFile mediaFile,
      [Function(double progress) callback]) async {
    final key = getKey(mediaFile.media);
    await push(mediaFile.file, key);

    return ServedMedia((b) => b
      ..uri = getDestinationUri(mediaFile.media)
      ..media = mediaFile.media.toBuilder()
      ..etag = 'a1b2c3'
      ..lengthInBytes = mediaFile.file.lengthSync());
  }

  @override
  Uri getDestinationUri(Media media) {
    final key = getKey(media);
    return Uri.parse('$endpointUrl/$key');
  }
}
