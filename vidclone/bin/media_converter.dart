import 'dart:async';
import 'package:vidlib/vidlib.dart';
import 'cloner_task.dart';
import 'package:built_collection/built_collection.dart';

// Returns a new [MediaFile] with a conversion applied to the input
// [MediaFile]'s underlying file
abstract class MediaConverter extends ClonerTask {
  // A unique id for this MediaConverter e.g. 'HEVC' for conversions of videos
  // into H.265
  String get id;

  MediaConverter();

  // Converts the specified media.
  Future<MediaFile> convert(
      MediaFile mediaFile, MediaConversionArgs conversionArgs,
      {Function(double progress) callback});

  static MediaConversionArgs createArgs(String id, List<String> args) =>
      MediaConversionArgs((b) => b
        ..id = id
        ..args = BuiltList.of(args).toBuilder());
}
