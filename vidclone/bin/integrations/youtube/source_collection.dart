import '../../source_collection.dart';

abstract class YoutubeSourceCollection extends SourceCollection {
  YoutubeSourceCollection(String identifier) : super(identifier);

  @override
  String get platformName => 'YouTube';

  @override
  String get platformUrl => 'https://www.youtube.com/';
}
