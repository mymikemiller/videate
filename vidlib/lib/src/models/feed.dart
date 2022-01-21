// Contains all the metadata associated with a media feed
import 'dart:convert';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:vidlib/src/models/served_media.dart';
import 'package:built_collection/built_collection.dart';
import '../serializers.dart';
part 'feed.g.dart';

abstract class Feed implements Built<Feed, FeedBuilder> {
  String get title;
  String get subtitle;
  String get description;
  String get link;
  String get author;
  String get email;
  String get imageUrl;

  // Newer episodes are at the end of the list
  BuiltList<ServedMedia> get mediaList;

  // The builder pattern is required by built_value, which we use for serialization
  Feed._();
  factory Feed([Function(FeedBuilder b) updates]) = _$Feed;
  factory Feed.fromJson(String json) {
    final data = jsonDecode(json);
    return jsonSerializers.deserialize(data) as Feed;
  }

  static Serializer<Feed> get serializer => _$feedSerializer;

  // Used only for debug purposes
  @override
  String toString() {
    return '$title';
  }

  String toJson() {
    final serialized = jsonSerializers.serialize(this);
    return jsonEncode(serialized);
  }

  Feed withMediaAdded(ServedMedia media) => withAllMediaAdded([media]);

  Feed withAllMediaAdded(List<ServedMedia> allMediaToAdd) {
    // Discard any media already in our list
    final nonDuplicatedMediaToAdd = List<ServedMedia>.from(allMediaToAdd)
      ..removeWhere((mediaToAdd) => mediaList.contains(mediaToAdd));
    return rebuild((b) => b.mediaList.addAll(nonDuplicatedMediaToAdd));
  }

  ServedMedia? get mostRecentMedia => mediaList.isEmpty
      ? null
      : mediaList.reduce((p0, p1) =>
          p0.media.source.releaseDate.isAfter(p1.media.source.releaseDate)
              ? p0
              : p1);
}
