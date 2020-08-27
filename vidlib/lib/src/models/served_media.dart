import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'media.dart';
part 'served_media.g.dart';

// Represents media whose file is available at the specified uri
abstract class ServedMedia implements Built<ServedMedia, ServedMediaBuilder> {
  Media get media;
  Uri get uri;
  String get etag;
  int get lengthInBytes;

  // The builder pattern is required by built_value, which we use for serialization
  ServedMedia._();
  factory ServedMedia([Function(ServedMediaBuilder b) updates]) = _$ServedMedia;
  static Serializer<ServedMedia> get serializer => _$servedMediaSerializer;
}
