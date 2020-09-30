import 'dart:async';
import 'package:vidlib/vidlib.dart';
import 'cloner_task.dart';
import 'package:built_collection/built_collection.dart';

// Returns a new [MediaFile] with a conversion applied to the input
// [MediaFile]'s underlying file
abstract class MediaConverter extends ClonerTask {
  // A unique id for this MediaConverter e.g. 'ffmpeg' for conversions using
  // the ffmpeg tool
  String get id;

  ClonerTaskArgs conversionArgs;

  MediaConverter();

  @override
  void configure(ClonerTaskArgs mediaConversionArgs) {
    conversionArgs = mediaConversionArgs;
  }

  // Converts the specified media.
  Future<MediaFile> convert(MediaFile mediaFile,
      {Function(double progress) callback});

  static ClonerTaskArgs createArgs(String id, List<String> args) =>
      ClonerTaskArgs((b) => b
        ..id = id
        ..args = BuiltList.of(args).toBuilder());
}
