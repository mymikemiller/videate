import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

/// Serializer for [Duration]. This class serializes
class DurationSerializer implements PrimitiveSerializer<Duration> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList<Type>([Duration]);
  @override
  final String wireName = 'Duration';

  // Serialize as h:mm:ss.ssssss
  @override
  Object serialize(Serializers serializers, Duration duration,
      {FullType specifiedType = FullType.unspecified}) {
    return duration.toString();
  }

  // Deserialize from h:mm:ss.ssssss
  @override
  Duration deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final durationString = serialized as String;
    final durationParts = durationString.split(':');
    final hours = int.parse(durationParts[0]);
    final minutes = int.parse(durationParts[1]);
    final secondParts = durationParts[2].split('.');
    final seconds = int.parse(secondParts[0]);
    final decimal = secondParts[1].padLeft(6, '0');
    final milliseconds = int.parse(decimal.substring(0, 3));
    final microseconds = int.parse(decimal.substring(3, 6));
    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
      microseconds: microseconds,
    );
  }
}
