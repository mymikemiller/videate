import '../rsync/rsync_feed_manager.dart';

class Cdn77FeedManager extends RsyncFeedManager {
  @override
  String get id => 'cdn77';

  Cdn77FeedManager() : super();

  @override
  String get endpointUrl => 'https://1928422091.rsc.cdn77.org';
}
