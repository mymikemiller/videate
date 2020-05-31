// Contains all the information required to find a collection of videos on a
// source platform.
abstract class SourceCollection {
  String get platformName;
  String get platformUrl;
  String get identifierMeaning;

  // identifier will mean a different thing for each cloner, but it's usually a
  // user id, channel id or something similar
  String identifier;

  SourceCollection(this.identifier);

  // Used only for debug purposes
  @override
  String toString() {
    return '$platformName source: $identifierMeaning $identifier';
  }
}
