import 'dart:async';
import 'package:vidlib/vidlib.dart';
import 'cloner_task.dart';
import 'package:built_collection/built_collection.dart';

/// Returns a new [MediaFile] with a conversion applied to the input
/// [MediaFile]'s underlying file
abstract class MediaConverter extends ClonerTask {
  static MediaConversionArgs createArgs(String id, List<String> args) {
    return MediaConversionArgs((b) => b
      ..id = id
      ..args = BuiltList.of(args).toBuilder());
  }

  MediaConverter();

  // Converts the specified media.
  Future<MediaFile> convert(
      MediaFile mediaFile, MediaConversionArgs conversionArgs,
      {Function(double progress) callback});
}
