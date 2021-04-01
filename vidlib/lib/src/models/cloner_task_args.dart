/// Contains the information sent into a singular ClonerTask, such as
/// Downloading, Converting, Uploading or Modifying a Feed
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
part 'cloner_task_args.g.dart';

/// Although [ClonerTask] is defined in the vidclone project, the args used to
/// configure them are defined in vidlib to take advantage of the BuiltValue
/// building we do here. If we start using BuildValue for the vidclone project,
/// we can move this class there.
abstract class ClonerTaskArgs
    implements Built<ClonerTaskArgs, ClonerTaskArgsBuilder> {
  // Matches the `id` in the [ClonerTask] these args apply to, e.g. 'youtube' for
  // the youtube downloader, or 'ffmpeg' for media conversions of videos into
  // H.264
  String get id;

  // A list of arguments to configure the [ClonerTask]. The format for these args
  // is not specified; it is up to the [ClonerTask] with the matching `id`
  // to know how to interpret these values.
  BuiltList<String> get args;

  // The builder pattern is required by built_value, which we use for
  // serialization
  ClonerTaskArgs._();
  factory ClonerTaskArgs(Function(ClonerTaskArgsBuilder a) updates) =>
      _$ClonerTaskArgs(updates);

  static Serializer<ClonerTaskArgs> get serializer =>
      _$clonerTaskArgsSerializer;

  // Gets the argument directly after the first argument that exactly matches
  // `name`
  String get(String name) {
    final index = args.indexOf(name);
    if (index == -1) {
      throw '$id cloner task argument not found: $name';
    }
    if (index + 1 == args.length) {
      throw '$id cloner task value not found for argument: $name';
    }
    final value = args[index + 1];
    return value;
  }

  // Used only for debug purposes
  @override
  String toString() {
    return 'id: $id, args: [${args.join(", ")}]';
  }
}
