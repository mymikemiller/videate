// Contains all the metadata associated with a source
import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:vidlib/vidlib.dart';
import 'platform.dart';
part 'source.g.dart';

// Represents the original source platform a video was originally sourced from,
// e.g. Youtube
abstract class Source implements Built<Source, SourceBuilder> {
  // The source platform, e.g. youtube
  Platform get platform;

  // The Uri where the video can be accessed on the source platform
  Uri get uri;

  // An id unique among all videos on the source platform, likely part of the
  // uri
  String get id;

  // The date the video was released on the source platform
  DateTime get releaseDate;

  // The builder pattern is required by built_value, which we use for
  // serialization
  Source._();
  factory Source([Function(SourceBuilder b) updates]) {
    var source = _$Source(updates);

    // Validate fields
    if (!source.releaseDate.isUtc) {
      throw ArgumentError(
          'Dates must be in UTC or built_value serialization will fail. Try adding .toUtc() to the DateTime.');
    }

    return source;
  }

  static Serializer<Source> get serializer => _$sourceSerializer;

  // Used only for debug purposes
  @override
  String toString() {
    final serialized = jsonSerializers.serialize(this);
    final encoded = json.encode(serialized);
    return encoded;
  }
}
