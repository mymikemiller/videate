import 'dart:io';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:vidlib/vidlib.dart';
import 'package:test/test.dart';

void main() {
  group('clonerConfiguration', () {
    //     "feedManager": {
    //         "id": "json_file",
    //         "args": [
    //             "path",
    //             "/Users/mikem/web/feeds/local_test_videos.json"
    //         ]
    //     },
    //     "downloader": {
    //         "id": "local",
    //         "args": [
    //             "path",
    //             "/Users/mikem/OneDrive/Projects/Web/videate/vidclone/test/resources/media"
    //         ]
    //     },
    //     "mediaConverter": {
    //         "id": "null",
    //         "args": []
    //     },
    //     "uploader": {
    //         "id": "internet_archive_cli",
    //         "args": [
    //             "credentialsFile",
    //             "/Users/mikem/videate/credentials/internet_archive/.ia-the_daily_talk_show"
    //         ]
    //     }
    // }

    final clonerConfig = ClonerConfiguration((c) => c
      ..feedManager = ClonerTaskArgs((a) => a
            ..id = 'test_feed_manager'
            ..args = ['test_arg', 'test_value'].toBuiltList().toBuilder())
          .toBuilder()
      ..downloader = ClonerTaskArgs((a) => a
            ..id = 'test_downloader'
            ..args = ['test_arg', 'test_value'].toBuiltList().toBuilder())
          .toBuilder()
      ..mediaConverter = ClonerTaskArgs((a) => a
            ..id = 'test_media_converter'
            ..args = ['test_arg', 'test_value'].toBuiltList().toBuilder())
          .toBuilder()
      ..uploader = ClonerTaskArgs((a) => a
            ..id = 'test_uploader'
            ..args = ['test_arg', 'test_value'].toBuiltList().toBuilder())
          .toBuilder());
    ;

    test('constructor', () {
      expect(clonerConfig.downloader.id, 'test_downloader');
      expect(clonerConfig.downloader.get('test_arg'), 'test_value');
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
