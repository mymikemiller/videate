// Contains all the metadata associated with a piece of media
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'source.dart';
part 'media.g.dart';

abstract class Media implements Built<Media, MediaBuilder> {
  String get title;
  String get description;

  // The source of the media, which contains information about how to access
  // the media on the platform on which it was originally released
  Source get source;

  BuiltList<String> get creators;
  Duration get duration;

  // The builder pattern is required by built_value, which we use for serialization
  Media._();
  factory Media(Function(MediaBuilder b) updates) => _$Media(updates);

  static Serializer<Media> get serializer => _$mediaSerializer;

  // Used only for debug purposes
  @override
  String toString() {
    return '$title at ${source.id}';
  }
}
