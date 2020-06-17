import 'dart:convert' show json;
import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';

class TestUtilities {
  // *DANGEROUS* If autofix is true, this test will update any given expectedJson
  // files to match the output. This will cause all tests to succeed and will
  // modify the files, which can be compared and checked into source control if
  // the modifications are correct (saving the files in VSCode with 'Format on
  // Save' enabled will format the file properly). This value should always be
  // *false* in the version checked into source control, but is useful when
  // making updates to json encodable types.
  static bool get autofix => false;

  static const _autofixHint = 'If the results of this run are correct, enable '
      'TestUtils.autofix and run the test again and update all expected files with '
      'the results of that run.';

  static Future<void> testJsonSerialization(
      Object encodableObject, File expectedJson) async {
    if (autofix) {
      final serialized = jsonSerializers.serialize(encodableObject);
      final encoded = json.encode(serialized);
      await expectedJson.writeAsString(encoded);
    } else {
      final expectedResultJsonString = await expectedJson.readAsString();
      final decodedExpectedResult = json.decode(expectedResultJsonString);

      var deserializedExpectedResult;
      try {
        // If this line fails for *expected* reasons, try toggling
        // TestUtilities.autofix to modify the expected results.
        deserializedExpectedResult =
            jsonSerializers.deserialize(decodedExpectedResult);
      } catch (e) {
        print(_autofixHint);
        rethrow;
      }

      // If this line fails for *expected* reasons, try toggling
      // TestUtilities.autofix to modify the expected results.
      expect(encodableObject, deserializedExpectedResult, reason: _autofixHint);
    }
  }

  static Future<void> _testSerialization(
      Object object, File expectedJson) async {
    // Test serialization
    await TestUtilities.testJsonSerialization(object, expectedJson);

    // Test encoding/decoding serialized object to/from a string
    final serialized = jsonSerializers.serialize(object);
    final encoded = json.encode(serialized);
    final decoded = json.decode(encoded);
    expect(decoded, serialized);

    // Test deserialization
    final deserialized = jsonSerializers.deserialize(serialized);
    expect(deserialized, object);
  }

  static Future<void> testListSerialization(
          BuiltList list, File expectedJson) =>
      _testSerialization(list, expectedJson);

  // Note that to support automatic deserialization of lists no matter where they
  // appear in the json, the built_value/built_collection serializer puts the
  // list inside an object under an empty string key. See
  // https://github.com/google/built_value.dart/issues/404
  static Future<void> testValueSerialization(Built value, File expectedJson) =>
      _testSerialization(value, expectedJson);
}
