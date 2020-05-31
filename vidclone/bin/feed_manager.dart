import 'package:vidlib/vidlib.dart';

abstract class FeedManager {
  // An id unique to this feed manager, e.g. "json_file".
  String get id;

  Feed get feed;
  Future<void> add(ServedVideo video);
  Future<void> addAll(List<ServedVideo> video);
}
