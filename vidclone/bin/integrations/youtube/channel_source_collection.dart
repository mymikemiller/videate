import 'source_collection.dart';

class YoutubeChannelSourceCollection extends YoutubeSourceCollection {
  YoutubeChannelSourceCollection(String channelId) : super(channelId);

  @override
  String get identifierMeaning => 'ChannelId';
}
