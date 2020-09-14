import 'dart:convert';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../serializers.dart';
import 'platform.dart';
part 'source_collection.g.dart';

// Contains all the information required to find a collection of media on the
// associated source platform.
abstract class SourceCollection
    implements Built<SourceCollection, SourceCollectionBuilder> {
  // The source Platform this collection is on, e.g. YouTube
  Platform get platform;

  // The value of `identifier` will mean a different thing for each collection,
  // but it's usually a user id, channel id, playlist id or something similar
  String get identifier;

  // Describes what the identifier refers to within the Platform (e.g. "user
  // id")
  String get identifierMeaning;

  // Names the SourceCollection for display purposes
  String get displayName;

  // The builder pattern is required by built_value, which we use for
  // serialization
  SourceCollection._();
  factory SourceCollection([Function(SourceCollectionBuilder b) updates]) =
      _$SourceCollection;
  factory SourceCollection.fromJson(String json) {
    final data = jsonDecode(json);
    return jsonSerializers.deserialize(data) as SourceCollection;
  }

  static Serializer<SourceCollection> get serializer =>
      _$sourceCollectionSerializer;

  // Used only for debug purposes
  @override
  String toString() {
    return 'source: $identifierMeaning $identifier';
  }
}
