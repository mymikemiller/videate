<<<<<<< HEAD
// Contains all the metadata associated with a piece of media
=======
>>>>>>> 0dcfd11 (rebase)
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'source.dart';
import 'media.dart';
part 'episode.g.dart';

abstract class Episode implements Built<Episode, EpisodeBuilder> {
  String get title;
  String get description;

  Media get media;

  // The source of the media, which contains information about how to access
  // the media on the platform on which it was originally released
  Source get source;

  BuiltList<String> get creators;
  Duration get duration;

  // The builder pattern is required by built_value, which we use for serialization
  Episode._();
  factory Episode(Function(EpisodeBuilder b) updates) => _$Episode(updates);

  static Serializer<Episode> get serializer => _$episodeSerializer;

  // Used only for debug purposes
  @override
  String toString() {
    return '$title at ${source.id}';
  }
}
