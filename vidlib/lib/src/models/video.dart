// Contains all the metadata associated with a video
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'source.dart';
part 'video.g.dart';

abstract class Video implements Built<Video, VideoBuilder> {
  String get title;
  String get description;

  // The source of the video, which contains information about how to access
  // the video on the platform on which it was originally released
  Source get source;

  BuiltList<String> get creators;
  Duration get duration;

  // The builder pattern is required by built_value, which we use for serialization
  Video._();
  factory Video([Function(VideoBuilder b) updates]) => _$Video(updates);

  static Serializer<Video> get serializer => _$videoSerializer;

  // Used only for debug purposes
  @override
  String toString() {
    return '$title at ${source.id}';
  }
}
