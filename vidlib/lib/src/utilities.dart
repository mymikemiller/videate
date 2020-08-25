import 'dart:io' as io;
import 'package:file/file.dart' as f;

class TimeResult {
  final dynamic returnValue;
  final Duration time;
  TimeResult(this.returnValue, this.time);
}

// Time the given function, returning an object containing the function's return
// value and the execution time
//
// To time function call: foo(1, 2, 3, f: 4, g: 5); Use: time(foo, [1,2,3], {#f:
//   4, #g: 5});
Future<TimeResult> time(Function function,
    [List positionalArguments, Map<Symbol, dynamic> namedArguments]) async {
  final stopwatch = Stopwatch()..start();
  final result =
      await Function.apply(function, positionalArguments, namedArguments);
  return TimeResult(result, stopwatch.elapsed);
}

// Copies the contents of `file` into a new file at the given `uri` on the
// given `fileSystem`. This function can be used to copy files from a file
// system other than the LocalFileSystem, such as the File library's
// MemoryFileSystem, where the file.copy() function fails.
Future<io.File> copyToFileSystem(
    io.File file, f.FileSystem destinationFileSystem, Uri uri) async {
  final newFile = destinationFileSystem.file(uri);
  newFile.createSync(recursive: true);

  // TODO: Don't read the whole file all at once. See:
  // https://stackoverflow.com/questions/20815913/how-to-read-a-file-line-by-line-in-dart
  // https://github.com/google/file.dart/issues/134
  List bytes = file.readAsBytesSync();

  return newFile.writeAsBytes(bytes);
}
