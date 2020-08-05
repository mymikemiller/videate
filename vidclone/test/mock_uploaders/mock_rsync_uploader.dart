import 'package:http/http.dart';
import '../../bin/integrations/rsync/rsync_uploader.dart';

class MockRsyncUploader extends RsyncUploader {
  MockRsyncUploader({rsyncRunner, Client client})
      : super(rsyncRunner: rsyncRunner);

  @override
  String get id => 'rsync';

  @override
  String get endpointUrl => 'http://example.com';
}