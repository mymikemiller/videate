library serializers;

import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_collection/built_collection.dart';
import 'package:vidlib/src/models/feed.dart';
import 'package:vidlib/src/models/media.dart';
import 'package:vidlib/src/models/cloner_task_args.dart';
import 'package:vidlib/src/models/served_media.dart';
import 'package:vidlib/src/models/platform.dart';
import 'package:vidlib/src/models/source.dart';
import 'package:vidlib/vidlib.dart';
import 'duration_serializer.dart';
part 'serializers.g.dart';

/// Collection of generated serializers for vidlib models.
@SerializersFor([
  ClonerConfiguration,
  Media,
  ClonerTaskArgs,
  ServedMedia,
  Feed,
  Platform,
  Source,
  BuiltMap,
])
final Serializers standardSerializers = (_$standardSerializers.toBuilder()
      // Serialize dates in a human-readable format instead of ms since epoch
      ..add(Iso8601DateTimeSerializer())
      // Serialize durations in a human-readable format (h:mm:ss.ssssss) instead of millisconds
      ..add(DurationSerializer()))
    .build();
final Serializers jsonSerializers = (standardSerializers.toBuilder()
      // Serialize as json for easy readability
      ..addPlugin(StandardJsonPlugin())
      ..addBuilderFactory(FullType(BuiltList, [FullType(ClonerConfiguration)]),
          () => ListBuilder<ClonerConfiguration>()))
    .build();

T standardDeserialize<T>(dynamic value) =>
    standardSerializers.deserializeWith<T>(
        standardSerializers.serializerForType(T) as Serializer<T>, value)!;

T jsonDeserialize<T>(dynamic value) => jsonSerializers.deserializeWith<T>(
    jsonSerializers.serializerForType(T) as Serializer<T>, value)!;

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
