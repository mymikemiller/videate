import 'package:vidlib/vidlib.dart';

abstract class FeedFormatter<T> {
  T format(Feed feed);
}
