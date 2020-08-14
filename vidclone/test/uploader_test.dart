import 'dart:io';
import 'package:file/memory.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import '../bin/integrations/local/save_to_disk_uploader.dart';
import '../bin/integrations/cdn77/cdn77_uploader.dart';
import '../bin/uploader.dart';
import '../bin/integrations/rsync/rsync_uploader.dart';
import 'mock_uploaders/mock_rsync_uploader.dart';
import 'mock_uploaders/mock_s3_uploader.dart';
import 'test_utilities.dart';

final memoryFileSystem = MemoryFileSystem();

class UploaderTest {
  final Uploader uploader;
  UploaderTest(this.uploader);
}

final successMockClient = (VideoFile videoFile) => MockClient((request) async {
      return Response('', 200, headers: {
        'etag': 'a1b2c3',
        'content-length': videoFile.file.lengthSync().toString()
      });
    });

void main() {
  final uploaderTests = [
    UploaderTest(SaveToDiskUploader(MemoryFileSystem().systemTempDirectory)),
    UploaderTest(MockS3Uploader()),
    UploaderTest(MockRsyncUploader()),
  ];

  for (var uploaderTest in uploaderTests) {
    group('${uploaderTest.uploader.id} uploader', () {
      test('uploads', () async {
        final file = File('test/resources/videos/video_1.mp4');

        final videoFile = VideoFile(Examples.video1, file);

        // The file should not exist at the destination yet
        uploaderTest.uploader.client = failureMockClient;
        final existingServedVideo =
            await uploaderTest.uploader.getExistingServedVideo(videoFile.video);
        expect(existingServedVideo == null, true);

        // Upload the file
        final servedVideo = await uploaderTest.uploader.upload(videoFile);
        expect(servedVideo == null, false);

        // Verify that the file now exists at the destination
        uploaderTest.uploader.client = successMockClient(videoFile);
        final finalServedVideo =
            await uploaderTest.uploader.getExistingServedVideo(videoFile.video);
        expect(finalServedVideo == null, false);

        // Both [upload] and [getExistingServedVideo] should return the same
        // object
        expect(finalServedVideo, servedVideo);
      });
    });

    uploaderTest.uploader.close();
  }
}
