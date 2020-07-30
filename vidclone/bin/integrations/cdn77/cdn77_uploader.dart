import '../rsync_uploader.dart/rsync_uploader.dart';

class Cdn77Uploader extends RsyncUploader {
  Cdn77Uploader(String username, String password) : super(username, password);

  @override
  String get id => 'CDN77';

  @override
  String get endpointUrl => 'https://1928422091.rsc.cdn77.org';
}
