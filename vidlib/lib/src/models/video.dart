// Contains all the metadata associated with a video
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
part 'video.g.dart';

abstract class Video implements Built<Video, VideoBuilder> {
  String get title;
  String get description;
  // The URL where the video can be accessed on the source platform (the
  // platform on which it was originally released)
  String get sourceUrl;
  // The date the video was released on the source platform
  DateTime get sourceReleaseDate;
  BuiltList<String> get creators;
  Duration get duration;

  // The builder pattern is required by built_value, which we use for serialization
  Video._();
  factory Video([Function(VideoBuilder b) updates]) {
    var video = _$Video(updates);

    // Validate fields
    if (!video.sourceReleaseDate.isUtc) {
      throw ArgumentError(
          'Dates must be in UTC or built_value serialization will fail. Try adding .toUtc() to the DateTime.');
    }

    return video;
  }

  static Serializer<Video> get serializer => _$videoSerializer;

  // Used only for debug purposes
  @override
  String toString() {
    return '${sourceReleaseDate.toString()} $sourceUrl: $title';
  }
}
