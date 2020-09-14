// Contains all the metadata associated with a piece of media
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
part 'media_conversion_args.g.dart';

abstract class MediaConversionArgs
    implements Built<MediaConversionArgs, MediaConversionArgsBuilder> {
  // Matches the `id` in the MediaConverter these args apply to, e.g. 'HEVC'
  // for conversions of videos into H.265
  String get id;

  // A list of arguments to configure the conversion. The format for these args
  // is not specified; it is up to the [MediaConverter] with the matching `id`
  // to know how to interpret these values.
  BuiltList<String> get args;

  // The builder pattern is required by built_value, which we use for
  // serialization
  MediaConversionArgs._();
  factory MediaConversionArgs(
          [Function(MediaConversionArgsBuilder b) updates]) =>
      _$MediaConversionArgs(updates);

  static Serializer<MediaConversionArgs> get serializer =>
      _$mediaConversionArgsSerializer;

  // Gets the argument directly after the first argument that exactly matches
  // `name`
  String get(String name) {
    final index = args.indexOf(name);
    final value = args[index + 1];
    return value;
  }

  // Used only for debug purposes
  @override
  String toString() {
    return '$id: [${args.join(",")}]';
  }
}
