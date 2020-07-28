import 'package:vidlib/vidlib.dart';

typedef Uri UriTransformer(Uri input);

abstract class FeedFormatter<T> {
  final UriTransformer uriTransformer;

  T format(Feed feed);

  FeedFormatter([this.uriTransformer]);

  Uri transformUri(Uri input) {
    return uriTransformer == null ? input : uriTransformer(input);
  }
}
