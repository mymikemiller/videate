import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:vidlib/src/utilities.dart';

void main() {
  group('time()', () {
    test('returns time and value', () async {
      final wait = (int delaySeconds) {
        return Future.delayed(
            Duration(seconds: delaySeconds), () => 'test result');
      };
      final timeResult = await time(wait, [2]);
      assert(timeResult.time >= Duration(seconds: 2));
      assert(timeResult.returnValue == 'test result');
    });
  });

  group('copyToFileSystem', () {
    test('copies from MemoryFileSystem to LocalFileSystem', () async {
      final memoryFileSystem = MemoryFileSystem();
      final localFileSystem = LocalFileSystem();

      final memoryTempDir = createTempDirectory(memoryFileSystem);
      final memoryFile = memoryTempDir.childFile('test.txt');
      memoryFile.writeAsStringSync('hello world');

      final localTempDir = createTempDirectory(localFileSystem);

      final localFile = await copyToFileSystem(memoryFile, localFileSystem,
          Uri.parse('${localTempDir.path}/test.txt'));

      assert(localFile.readAsStringSync() == 'hello world');
    });
  });
}
