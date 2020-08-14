import '../rsync/rsync_uploader.dart';

class Cdn77Uploader extends RsyncUploader {
  Cdn77Uploader() : super();

  @override
  String get id => 'cdn77';

  @override
  String get endpointUrl => 'https://1928422091.rsc.cdn77.org';
}
