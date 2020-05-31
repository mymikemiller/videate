// Contains all the metadata associated with a video feed
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:vidlib/src/models/served_video.dart';
import 'package:built_collection/built_collection.dart';
import '../../vidlib.dart';
part 'feed.g.dart';

abstract class Feed implements Built<Feed, FeedBuilder> {
  String get title;
  String get subtitle;
  String get description;
  String get link;
  String get author;
  String get email;
  String get imageUrl;
  BuiltList<ServedVideo> get videos;

  // The builder pattern is required by built_value, which we use for serialization
  Feed._();
  factory Feed([Function(FeedBuilder b) updates]) = _$Feed;
  factory Feed.fromJson(Map<String, dynamic> data) {
    return jsonSerializers.deserialize(data) as Feed;
  }

  static Serializer<Feed> get serializer => _$feedSerializer;

  // Used only for debug purposes
  @override
  String toString() {
    return '$title';
  }

  Feed withVideoAdded(ServedVideo video) {
    return rebuild((b) => b.videos.add(video));
  }

  Feed withAllVideosAdded(List<ServedVideo> videos) {
    return rebuild((b) => b.videos.addAll(videos));
  }

  ServedVideo get mostRecentVideo => videos.isEmpty ? null : videos[0];
}
