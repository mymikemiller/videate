import 'dart:io';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import '../bin/integrations/local/save_to_disk_uploader.dart';
import '../bin/uploader.dart';
import 'mock_uploaders/mock_s3_uploader.dart';

final memoryFileSystem = MemoryFileSystem();

class UploaderTest {
  final Uploader uploader;
  UploaderTest(this.uploader);
}

void main() {
  final uploaderTests = [
    UploaderTest(SaveToDiskUploader(MemoryFileSystem().systemTempDirectory)),
    UploaderTest(MockS3Uploader()),
  ];

  for (var uploaderTest in uploaderTests) {
    group('${uploaderTest.uploader.id} uploader', () {
      test('uploads', () async {
        final file = File('test/resources/videos/six_second_video.mp4');

        final videoFile = VideoFile(Examples.video1, file);

        // The file should not exist at the destination yet
        final existsInitially =
            await uploaderTest.uploader.existsAtDestination(Examples.video1);
        expect(existsInitially, false);

        // Upload the file
        final servedVideo = await uploaderTest.uploader.upload(videoFile);
        expect(servedVideo == null, false);

        // Verify that the file now exists at the destination
        final existsFinally =
            await uploaderTest.uploader.existsAtDestination(Examples.video1);
        expect(existsFinally, true);
      });
    });
  }
}
