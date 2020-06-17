import 'package:vidlib/vidlib.dart';

import '../../source_collection.dart';

abstract class YoutubeSourceCollection extends SourceCollection {
  YoutubeSourceCollection(String identifier) : super(identifier);

  @override
  Platform get platform => Platform(
        (p) => p
          ..id = 'youtube'
          ..uri = Uri.parse('https://www.youtube.com/'),
      );
}
