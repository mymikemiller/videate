// Contains all the information required to find a collection of videos on the
// associated source platform.

abstract class SourceCollection {
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
    return 'source: $identifierMeaning $identifier';
  }
}
