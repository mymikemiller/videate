import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
part 'platform.g.dart';

// Represents the platform where the media was originally released, e.g. youtube
abstract class Platform implements Built<Platform, PlatformBuilder> {
  // The Uri to the platform's main page, e.g. 'http://www.youtube.com'
  Uri get uri;

  // An id unique among all platforms, e.g. 'youtube'
  String get id;

  // The builder pattern is required by built_value, which we use for serialization
  Platform._();
  factory Platform(Function(PlatformBuilder b) updates) => _$Platform(updates);

  static Serializer<Platform> get serializer => _$platformSerializer;

  // Used only for debug purposes
  @override
  String toString() {
    return uri.toString();
  }
}
