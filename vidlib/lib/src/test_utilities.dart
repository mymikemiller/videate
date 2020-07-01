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
      Object encodableObject, File expectedJson) async {
    print('testJsonSerialization');
    final serialized = jsonSerializers.serialize(encodableObject);
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
        deserializedExpectedResult =
            jsonSerializers.deserialize(decodedExpectedResult);
      } catch (e) {
        print(_autofixHint);
        rethrow;
      }

      if ((deserializedExpectedResult as BuiltList).isNotEmpty &&
          (encodableObject as BuiltList).isNotEmpty) {
        final other = deserializedExpectedResult[0];
        final video = (encodableObject as BuiltList)[0];

        print('video.source: ' + (video.source).toString());
        print('other.source: ' + (other.source).toString());

        print(
            'identical(other, this): ' + (identical(other, video)).toString());
        print('other is Video: ' + (other is Video).toString());
        print('title == other.title: ' +
            (other is Video && video.title == other.title).toString());
        print('description == other.description: ' +
            (other is Video && video.description == other.description)
                .toString());
        print('source == other.source: ' +
            (other is Video && video.source == other.source).toString());
        print('creators == other.creators: ' +
            (other is Video && video.creators == other.creators).toString());
        print('duration == other.duration: ' +
            (other is Video && video.duration == other.duration).toString());
      }

      // If this line fails for *expected* reasons, try toggling
      // TestUtilities.autofix to modify the expected results file.
      print('encodableObject == deserializedExpectedResult: ' +
          (encodableObject == deserializedExpectedResult).toString());
      expect(encodableObject, deserializedExpectedResult, reason: _autofixHint);
    }
  }

  static Future<void> _testSerialization(
      Object object, File expectedJson) async {
    print('_testSerialization');
    // Test serialization
    print('calling testJsonSerialization');
    await TestUtilities.testJsonSerialization(object, expectedJson);
    print('testJsonSerialization done');

    // Test encoding/decoding serialized object to/from a string
    final serialized = jsonSerializers.serialize(object);
    final encoded = json.encode(serialized);
    final decoded = json.decode(encoded);
    print('expect(decoded, serialized)');
    expect(decoded, serialized);
    print('expect(decoded, serialized) done');

    // Test deserialization
    final deserialized = jsonSerializers.deserialize(serialized);
    print('deserialized == object: ' + (deserialized == object).toString());
    if (object.runtimeType.toString().contains('BuiltList')) {
      final objectList = object as BuiltList;
      final deserializedList = object as BuiltList;
      print('deserialized[0] == object[0]: ' +
          (deserializedList[0] == objectList[0]).toString());
    }
    print('expect(deserialized, object)');
    expect(deserialized, object);
    print('expect(deserialized, object done)');
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

  static Future<void> testXml(
      xml.XmlDocument observed, File expectedXml) async {
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
