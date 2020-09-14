import 'dart:io';

import '../../bin/integrations/rsync/rsync_uploader.dart';
import '../test_utilities.dart';

class MockRsyncUploader extends RsyncUploader {
  MockRsyncUploader();

  @override
  String get id => 'rsync';

  @override
  ProcessResult Function(String executable, List<String> arguments)
      get processRunner => noopProcessRun;

  @override
  String get endpointUrl => 'http://example.com';
}
