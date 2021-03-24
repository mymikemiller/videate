import 'dart:io';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:built_collection/built_collection.dart';
import 'package:test/test.dart';
import 'package:vidlib/vidlib.dart';
import '../bin/integrations/local/save_to_disk_uploader.dart';
import '../bin/integrations/cdn77/cdn77_uploader.dart';
import '../bin/uploader.dart';
import '../bin/integrations/rsync/rsync_uploader.dart';
import 'mock_uploaders/mock_rsync_uploader.dart';
import 'test_utilities.dart';

final memoryFileSystem = MemoryFileSystem();

class UploaderTest {
  final Uploader uploader;
  UploaderTest(this.uploader);
}

final successMockClient = (MediaFile mediaFile) => MockClient((request) async {
      return Response('', 200, headers: {
        'etag': 'a1b2c3',
        'content-length': mediaFile.file.lengthSync().toString()
      });
    });

void main() {
  final uploaderTests = [
    UploaderTest(SaveToDiskUploader(createTempDirectory(MemoryFileSystem()))
      ..configure(ClonerTaskArgs((a) => a
        ..id = 'save_to_disk'
        ..args = ['feedName', 'test_feed', 'platformId', 'test_platform']
            .toBuiltList()
            .toBuilder()))),
    UploaderTest(MockRsyncUploader()),
  ];

  for (var uploaderTest in uploaderTests) {
    group('${uploaderTest.uploader.id} uploader', () {
      test('uploads', () async {
        final file = LocalFileSystem().file('test/resources/media/video_1.mp4');

        final mediaFile = MediaFile(Examples.media1, file);

        // The file should not exist at the destination yet
        uploaderTest.uploader.client = failureMockClient;
        final existingservedMedia =
            await uploaderTest.uploader.getExistingServedMedia(mediaFile.media);
        expect(existingservedMedia == null, true);

        // Upload the file
        final servedMedia = await uploaderTest.uploader.upload(mediaFile);
        expect(servedMedia == null, false);

        // Verify that the file now exists at the destination
        uploaderTest.uploader.client = successMockClient(mediaFile);
        final finalservedMedia =
            await uploaderTest.uploader.getExistingServedMedia(mediaFile.media);
        expect(finalservedMedia == null, false);

        // Both [upload] and [getExistingservedMedia] should return the same
        // object
        expect(finalservedMedia, servedMedia);
      });
    });

    uploaderTest.uploader.close();
  }
}
