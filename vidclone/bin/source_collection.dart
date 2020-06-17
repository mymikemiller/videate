// Contains all the information required to find a collection of videos on a
// source platform.
import 'package:vidlib/vidlib.dart';

abstract class SourceCollection {
  Platform platform;

  // identifier will mean a different thing for each cloner, but it's usually a
  // user id, channel id or something similar
  String identifier;

  // Describes what the identifier refers to within the Platform (e.g. "user
  // id")
  String get identifierMeaning;

  SourceCollection(this.identifier);

  // Used only for debug purposes
  @override
  String toString() {
    return '${platform.id} source: $identifierMeaning $identifier';
  }
}
