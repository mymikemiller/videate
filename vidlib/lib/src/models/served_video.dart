import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'video.dart';
part 'served_video.g.dart';

// Represents a video whose file is available at the specified uri
abstract class ServedVideo implements Built<ServedVideo, ServedVideoBuilder> {
  Video get video;
  Uri get uri;
  String get etag;
  int get lengthInBytes;

  // The builder pattern is required by built_value, which we use for serialization
  ServedVideo._();
  factory ServedVideo([Function(ServedVideoBuilder b) updates]) = _$ServedVideo;
  static Serializer<ServedVideo> get serializer => _$servedVideoSerializer;
}
