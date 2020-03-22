library serializers;

import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/src/models/video.dart';

part 'serializers.g.dart';

/// Collection of generated serializers for vidlib models.
@SerializersFor([
  Video,
])
final Serializers standardSerializers = (_$standardSerializers.toBuilder()
      // Serialize dates in a human-readable format instead of ms since epoch
      ..add(Iso8601DateTimeSerializer()))
    .build();
final Serializers jsonSerializers = (standardSerializers.toBuilder()..addPlugin(
    // Serialize as json for easy readability
    StandardJsonPlugin())).build();

T standardDeserialize<T>(dynamic value) => standardSerializers
    .deserializeWith<T>(standardSerializers.serializerForType(T), value);
T jsonDeserialize<T>(dynamic value) => jsonSerializers.deserializeWith<T>(
    jsonSerializers.serializerForType(T), value);

class SerializationHelper {
  static final SerializationHelper _singleton = SerializationHelper._internal();

  factory SerializationHelper() {
    return _singleton;
  }

  SerializationHelper._internal();

  BuiltList<T> deserializeStandardListOf<T>(dynamic value) =>
      BuiltList.from(value
          .map((value) => standardDeserialize<T>(value))
          .toList(growable: false));
  BuiltList<T> deserializeJsonListOf<T>(dynamic value) => BuiltList.from(
      value.map((value) => jsonDeserialize<T>(value)).toList(growable: false));
}

final serializationHelper = SerializationHelper();
