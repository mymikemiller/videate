import 'package:http/src/client.dart';
import 'package:mockito/mockito.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import 'dart:io';
import 'package:vidlib/vidlib.dart';
import '../../bin/integrations/youtube/youtube_downloader.dart';

// MockYoutubeDownloader implements, not extends, YoutubeDownloader because
// YoutubeDownloader's only constructors are factory constructors which can't
// be extended. So we implement it instead and send all calls to a delegate we
// create which uses an API we can mock. See
// https://stackoverflow.com/questions/18564676/extending-a-class-with-only-one-factory-constructor
class MockYoutubeDownloader implements YoutubeDownloader {
  @override
  Platform get platform => Platform(
        (p) => p
          ..id = 'youtube'
          ..uri = Uri(path: 'https://www.youtube.com'),
      );

  final YoutubeDownloader _delegate;
  static final _mockYoutubeExplode = MockYoutubeExplode();

  // The file that will be "downloaded"
  final File file;

  MockYoutubeDownloader(this.file)
      : _delegate = YoutubeDownloader(_mockYoutubeExplode) {
    final yt_explode.StreamManifest mockStreamManifest = MockStreamManifest();
    final yt_explode.StreamsClient mockStreamsClient = MockStreamsClient();
    final yt_explode.ChannelClient mockChannelClient = MockChannelClient();
    when(mockStreamsClient.getManifest('abc12345678'))
        .thenAnswer((realInvocation) => Future.value(mockStreamManifest));

    final mockStreamInfo = yt_explode.MuxedStreamInfo(
        18,
        Uri.parse(
            'https://r4---sn-bvvbax4pcxg-naje.googlevideo.com/videoplayback?expire=1593062474&ei=6t_zXu7OJ5mHkgagxp_4BQ&ip=2605%3Aa601%3Aa9b3%3Af900%3A7c9e%3A2092%3A2934%3A8bd9&id=o-AIDNpzWbjS0BJtVrHOU-dOdheDdhWDlDT3CDAD77NZEZ&itag=18&source=youtube&requiressl=yes&mh=ee&mm=31%2C29&mn=sn-bvvbax4pcxg-naje%2Csn-vgqskned&ms=au%2Crdu&mv=m&mvi=3&pl=42&initcwndbps=1463750&vprv=1&mime=video%2Fmp4&gir=yes&clen=6513153&ratebypass=yes&dur=85.542&lmt=1573895279325191&mt=1593040836&fvip=4&c=WEB&txp=5531432&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cvprv%2Cmime%2Cgir%2Cclen%2Cratebypass%2Cdur%2Clmt&sig=AOq0QJ8wRQIgIC2xPHSeTb9gu9EPpbkOV9eH8dIfFarXEF7obiKv_mMCIQD9n5qLVBa6hzVJfLBd66deMS7gDw60IbJ8aN2i7y4uQw%3D%3D&lsparams=mh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AG3C_xAwRQIgIo2Oq8fk3bbzfB9FbtIpFTNDaLxEbGs5qaIJhjW5Pb8CIQC0t2RjdE1U0PxcWPwCOnI6DBVwjKEO9Q3Zx1XxOU4iTA%3D%3D'),
        yt_explode.StreamContainer.mp4,
        yt_explode.FileSize(6211426),
        yt_explode.Bitrate(595238),
        'mp4a.40.2',
        'avc1.42001e',
        '360p',
        yt_explode.VideoQuality.medium360,
        yt_explode.VideoResolution(640, 360),
        yt_explode.Framerate(30));

    Stream<yt_explode.Video> generateMockVideoStream() => Stream.fromIterable([
          yt_explode.Video(
              yt_explode.VideoId('33333333333'),
              'Title 3',
              'Author 3`',
              yt_explode.ChannelId('UC9CuvdOVfMPvKCiwdGKL3cQ'),
              DateTime.parse('2020-01-03 03:33:00.000Z'),
              DateTime.parse('2020-01-03 03:33:00.000Z'),
              'Description 3',
              Duration(minutes: 3, seconds: 33),
              yt_explode.ThumbnailSet('33333333333'),
              [],
              yt_explode.Engagement(95128, 12708, 25)),
          yt_explode.Video(
              yt_explode.VideoId('22222222222'),
              'Title 2',
              'Author 2`',
              yt_explode.ChannelId('UC9CuvdOVfMPvKCiwdGKL3cQ'),
              DateTime.parse('2020-01-02 02:22:00.000Z'),
              DateTime.parse('2020-01-02 02:22:00.000Z'),
              'Description 2',
              Duration(minutes: 2, seconds: 22),
              yt_explode.ThumbnailSet('22222222222'),
              [],
              yt_explode.Engagement(95128, 12708, 25)),
          yt_explode.Video(
              yt_explode.VideoId('11111111111'),
              'Title 1',
              'Author 1`',
              yt_explode.ChannelId('UC9CuvdOVfMPvKCiwdGKL3cQ'),
              DateTime.parse('2020-01-01 01:11:00.000Z'),
              DateTime.parse('2020-01-01 01:11:00.000Z'),
              'Description 1',
              Duration(minutes: 1, seconds: 11),
              yt_explode.ThumbnailSet('11111111111'),
              [],
              yt_explode.Engagement(95128, 12708, 25)),
        ]);

    when(mockStreamManifest.muxed).thenReturn([mockStreamInfo]);

    final yt_explode.VideoClient mockVideoClient = MockVideoClient();
    when(_mockYoutubeExplode.videos).thenReturn(mockVideoClient);

    when(mockVideoClient.streamsClient).thenReturn(mockStreamsClient);

    when(_mockYoutubeExplode.channels).thenReturn(mockChannelClient);

    when(mockStreamsClient.get(mockStreamInfo))
        .thenAnswer((realInvocation) => file.openRead());

    when(mockChannelClient
            .getUploads(yt_explode.ChannelId('UC9CuvdOVfMPvKCiwdGKL3cQ')))
        .thenAnswer((realInvocation) => generateMockVideoStream());
  }

  @override
  Stream<Media> allMedia() => _delegate.allMedia();

  @override
  Stream<Media> reverseChronologicalMedia([DateTime after]) =>
      _delegate.reverseChronologicalMedia(after);

  @override
  String getSourceUniqueId(Media media) => _delegate.getSourceUniqueId(media);

  @override
  Future<Media> mostRecentMedia() => _delegate.mostRecentMedia();

  @override
  Future<MediaFile> download(Media media,
          {Function(double progress) callback}) =>
      _delegate.download(media);

  @override
  void configure(ClonerTaskArgs args) => _delegate.configure(args);

  @override
  void close() {
    _delegate.close();
  }

  @override
  int get slidingWindowSize => 1;

  @override
  Future<Feed> createEmptyFeed() => _delegate.createEmptyFeed();

  @override
  Client get client => _delegate.client;
  @override
  set client(Client _client) => _delegate.client = _client;

  @override
  dynamic get processRunner => _delegate.processRunner;
  @override
  set processRunner(_processRunner) => _delegate.processRunner = _processRunner;

  @override
  dynamic get processStarter => _delegate.processStarter;
  @override
  set processStarter(_processStarter) =>
      _delegate.processStarter = _processStarter;

  @override
  yt_explode.ChannelId channelId;
}

class MockYoutubeExplode extends Mock implements yt_explode.YoutubeExplode {}

class MockVideoClient extends Mock implements yt_explode.VideoClient {}

class MockStreamsClient extends Mock implements yt_explode.StreamsClient {}

class MockChannelClient extends Mock implements yt_explode.ChannelClient {}

class MockStreamManifest extends Mock implements yt_explode.StreamManifest {}

class MockMuxedStreamInfo extends Mock implements yt_explode.MuxedStreamInfo {}
