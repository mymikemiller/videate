import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';

void main() {
  group('clonerConfiguration', () {
    final clonerConfig = ClonerConfiguration((c) => c
      ..displayName = 'Test Cloner Config'
      ..feedName = 'testfeed'
      ..sourceCollection = SourceCollection((s) => s
        ..displayName = 'Test Display Name'
        ..platform = Platform((p) => p
          ..id = 'test_platform'
          ..uri = Uri.parse('http://example.com')).toBuilder()
        ..identifierMeaning = 'Test Identifier'
        ..identifier = 'abcdefg').toBuilder()
      ..mediaConversionArgs = MediaConversionArgs((m) => m
        ..id = 'ffmpeg'
        ..args = ['vcodec', 'libx264', 'height', '240', 'crf', '30']
            .toBuiltList()
            .toBuilder()).toBuilder()
      ..uploaderId = 'test_uploader_id'
      ..feedManagerId = 'test_feed_manager_id');
    ;

    test('constructor', () {
      expect(clonerConfig.displayName, 'Test Cloner Config');
      expect(clonerConfig.sourceCollection.platform.id, 'test_platform');
    });

    test('JSON serialization/deserialization', () async {
      await TestUtilities.testValueSerialization(clonerConfig,
          File('test/resources/cloner_configuration_serialized_expected.json'),
          specifiedType: FullType(ClonerConfiguration));
    });

    test('JSON serialization of lists', () async {
      await TestUtilities.testListSerialization(
          BuiltList<ClonerConfiguration>.from([clonerConfig]),
          File(
              'test/resources/cloner_configuration_list_serialized_expected.json'),
          specifiedType: FullType(BuiltList, [FullType(ClonerConfiguration)]));
    });
  });
}
