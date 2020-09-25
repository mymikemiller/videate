import 'dart:convert' show json;
import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart' as xml;

class TestUtilities {
  // *DANGEROUS* If autofix is true, this test will update any given
  // expectedJson files to match the output. This will cause all tests to
  // succeed and will modify the files, which can be compared and checked into
  // source control if the modifications are correct (saving the files in
  // VSCode with 'Format on Save' enabled will format the file properly). This
  // value should always be *false* in the version checked into source control,
  // but is useful when making updates to xml and json encodable types.
  static bool get autofix => false;

  static const _autofixHint = 'If the results of this run are correct, enable '
      'TestUtils.autofix and run the test again to update all expected files '
      'with the results of that run.';

  static final String Function(xml.XmlDocument) _formatXml =
      (xml.XmlDocument input) {
    final formatted = input
        .toXmlString(pretty: true)
        .replaceFirst('<?xml version="1.0"?>', '<?xml version="1.0" ?>')
        .replaceAll('/>', ' />');
    if (formatted.endsWith('\n')) {
      return formatted;
    } else {
      return formatted + '\n';
    }
  };

  static bool _equalsIgnoringWhitespace(String observed, String expected) {
    final whitespaceRegex = RegExp(r'\s');
    final modifiedObserved = observed.replaceAll(whitespaceRegex, '');
    final modifiedExpected = expected.replaceAll(whitespaceRegex, '');
    return modifiedObserved == modifiedExpected;
  }

  static bool _needsFixing(String result, File expectedResult) {
    final expectedString = expectedResult.readAsStringSync();
    return !_equalsIgnoringWhitespace(result, expectedString);
  }

  static Future<void> testJsonSerialization(
      Object encodableObject, File expectedJson,
      {FullType specifiedType = FullType.unspecified}) async {
    if (autofix) {
      expectedJson.createSync();
    }

    final serialized = jsonSerializers.serialize(encodableObject,
        specifiedType: specifiedType);
    final encoded = json.encode(serialized);
    if (autofix && _needsFixing(encoded, expectedJson)) {
      await expectedJson.writeAsString(encoded + '\n');
    } else {
      final expectedResultJsonString = await expectedJson.readAsString();
      final decodedExpectedResult = json.decode(expectedResultJsonString);

      var deserializedExpectedResult;
      try {
        // If this line fails for *expected* reasons, try toggling
        // TestUtilities.autofix to modify the expected results.
        deserializedExpectedResult = jsonSerializers
            .deserialize(decodedExpectedResult, specifiedType: specifiedType);
      } catch (e) {
        print(_autofixHint);
        rethrow;
      }

      // If this line fails for *expected* reasons, try toggling
      // TestUtilities.autofix to modify the expected results file.
      expect(encodableObject, deserializedExpectedResult, reason: _autofixHint);
    }
  }

  static Future<void> _testSerialization(Object object, File expectedJson,
      {FullType specifiedType = FullType.unspecified}) async {
    // Test serialization
    await TestUtilities.testJsonSerialization(object, expectedJson,
        specifiedType: specifiedType);

    // Test encoding/decoding serialized object to/from a string
    final serialized =
        jsonSerializers.serialize(object, specifiedType: specifiedType);
    final encoded = json.encode(serialized);
    final decoded = json.decode(encoded);
    expect(decoded, serialized);

    // Test deserialization
    final deserialized =
        jsonSerializers.deserialize(serialized, specifiedType: specifiedType);
    expect(deserialized, object);
  }

  static Future<void> testListSerialization(BuiltList list, File expectedJson,
          {FullType specifiedType = FullType.unspecified}) =>
      _testSerialization(list, expectedJson, specifiedType: specifiedType);

  // Note that to support automatic deserialization of lists no matter where they
  // appear in the json, the built_value/built_collection serializer puts the
  // list inside an object under an empty string key. See
  // https://github.com/google/built_value.dart/issues/404
  static Future<void> testValueSerialization(Built value, File expectedJson,
          {FullType specifiedType = FullType.unspecified}) =>
      _testSerialization(value, expectedJson, specifiedType: specifiedType);

  static Future<void> testXml(
      xml.XmlDocument observed, File expectedXml) async {
    if (autofix) {
      expectedXml.createSync();
    }

    final formattedObserved = _formatXml(observed);

    if (autofix && _needsFixing(formattedObserved, expectedXml)) {
      await expectedXml.writeAsString(formattedObserved);
    } else {
      final expectedString = await expectedXml.readAsString();
      final expectedFeed = xml.parse(expectedString);
      final formattedExpected = _formatXml(expectedFeed);
      expect(formattedObserved, formattedExpected, reason: _autofixHint);
    }
  }
}
