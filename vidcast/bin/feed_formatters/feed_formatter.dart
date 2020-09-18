import 'package:vidlib/vidlib.dart';

typedef Uri UriTransformer(Uri input);

abstract class FeedFormatter<T> {
  final List<UriTransformer> uriTransformers;

  T format(Feed feed);

  FeedFormatter([this.uriTransformers]);

  Uri transformUri(Uri input) {
    if (uriTransformers != null) {
      // Run all the transformers in order
      return uriTransformers.fold(
          input, (previousValue, transformer) => transformer(previousValue));
    }
    return input;
  }
}
