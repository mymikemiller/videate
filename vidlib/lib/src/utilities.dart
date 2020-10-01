import 'dart:io' as io;
import 'package:file/file.dart' as f;
import 'package:file/local.dart';
import 'package:path/path.dart';
import 'package:console/console.dart';

class TimeResult {
  final dynamic returnValue;
  final Duration time;
  TimeResult(this.returnValue, this.time);
}

// Time the given function, returning an object containing the function's
// return value and the execution time
//
// To time function call: foo(1, 2, 3, f: 4, g: 5); Use: time(foo, [1,2,3],
//   {#f: 4, #g: 5});
//
// `progressCallbackName`, if set, will display a progress bar by passing in a
// callback to the named parameter of the specified name. This callback is
// expected to have the following signature: void Function(double progress)
Future<TimeResult> time(
  Function function, [
  List positionalArguments,
  Map<Symbol, dynamic> namedArguments,
  String progressCallbackName,
]) async {
  final progressCallbackSymbol = Symbol(progressCallbackName);
  // If the user specified that the function to time accepts a progress
  // callback (by specifying progressCallbackName), this function handles
  // creating and displaying the progress bar while the function is timed. If
  // the callback is already specified in namedArguments, no progress bar will
  // be created.
  if (progressCallbackName != null &&
      !namedArguments.containsKey(progressCallbackSymbol)) {
    final progressBar = ProgressBar();
    final progressCallback = (double progress) {
      updateProgressBar(progressBar, progress);
    };
    namedArguments[progressCallbackSymbol] = progressCallback;
  }
  final stopwatch = Stopwatch()..start();
  final result =
      await Function.apply(function, positionalArguments, namedArguments);
  return TimeResult(result, stopwatch.elapsed);
}

void updateProgressBar(ProgressBar progressBar, double progress) {
  final progressInt = (progress * 100).round();
  try {
    progressBar.update(progressInt);
  } on io.StdoutException catch (e) {
    if (e.message == 'Could not get terminal size') {
      print('If using VSCode, make sure you\'re using the Integrated Terminal,'
          ' as the Debug Console does not support cursor positioning '
          'necessary to display the progress bar. Set `"console": '
          '"terminal"` in launch.json.');
    }
  }
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

Future<io.File> ensureLocal(f.File file) async {
  if (file.fileSystem != LocalFileSystem()) {
    final tempDir = LocalFileSystem().systemTempDirectory.createTempSync();
    final outputPath = '${tempDir.path}/${basename(file.path)}';
    final uri = Uri.parse(outputPath);
    file = await copyToFileSystem(file, LocalFileSystem(), uri);
  }
  return file;
}

// Return a map where the keys are results of calling valueAccessor on an item,
// and the values are lists of all items with the same value
Map<Value, Iterable<Item>> mapByValue<Item, Value>(
    Iterable<Item> list, Value Function(Item) valueAccessor) {
  return list.fold({}, (map, item) {
    final value = valueAccessor(item);
    map.update(value, (existingList) {
      return [...existingList, item];
    }, ifAbsent: () => <Item>[item]);
    return map;
  });
}

// Get any values that are duplicated among the items in `list`.
// `valueAccessor` can be any function that operates on an item in the list,
// such as accessing one of its property values.
List<Value> getDuplicatesByAccessor<Item, Value>(
    Iterable<Item> list, Value Function(Item) valueAccessor) {
  final reversedMap = mapByValue(list, valueAccessor);
  // Remove all unique values so we're left with only values that are
  // duplicated
  final nonUnique = reversedMap..removeWhere((key, value) => value.length == 1);
  return nonUnique.keys.toList();
}
