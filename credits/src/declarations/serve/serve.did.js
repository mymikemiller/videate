export const idlFactory = ({ IDL }) => {
  const Platform = IDL.Record({ 'id' : IDL.Text, 'uri' : IDL.Text });
  const Source = IDL.Record({
    'id' : IDL.Text,
    'uri' : IDL.Text,
    'platform' : Platform,
    'releaseDate' : IDL.Text,
  });
  const Media = IDL.Record({
    'uri' : IDL.Text,
    'title' : IDL.Text,
    'lengthInBytes' : IDL.Nat,
    'source' : Source,
    'etag' : IDL.Text,
    'description' : IDL.Text,
    'nftTokenId' : IDL.Opt(IDL.Nat64),
    'durationInMicroseconds' : IDL.Nat,
  });
  const Feed = IDL.Record({
    'title' : IDL.Text,
    'link' : IDL.Text,
    'description' : IDL.Text,
    'email' : IDL.Text,
    'author' : IDL.Text,
    'imageUrl' : IDL.Text,
    'mediaList' : IDL.Vec(Media),
    'subtitle' : IDL.Text,
  });
  const HeaderField = IDL.Tuple(IDL.Text, IDL.Text);
  const HttpRequest = IDL.Record({
    'url' : IDL.Text,
    'method' : IDL.Text,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
  });
  const Token = IDL.Record({});
  const StreamingCallbackHttpResponse = IDL.Record({
    'token' : Token,
    'body' : IDL.Vec(IDL.Nat8),
  });
  const StreamingStrategy = IDL.Variant({
    'Callback' : IDL.Record({
      'token' : Token,
      'callback' : IDL.Func([Token], [StreamingCallbackHttpResponse], []),
    }),
  });
  const HttpResponse = IDL.Record({
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
    'streaming_strategy' : IDL.Opt(StreamingStrategy),
    'status_code' : IDL.Nat16,
  });
  const Serve = IDL.Service({
    'addFeed' : IDL.Func([IDL.Text, Feed], [IDL.Nat], []),
    'deleteFeed' : IDL.Func([IDL.Text], [], ['oneway']),
    'getAllFeedKeys' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getAllFeedMediaDetails' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Text, IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text))))],
        [],
      ),
    'getAllFeedSummaries' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text))],
        [],
      ),
    'getAllFeeds' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Text, Feed))],
        ['query'],
      ),
    'getFeed' : IDL.Func([IDL.Text], [IDL.Opt(Feed)], ['query']),
    'getFeedMediaDetails' : IDL.Func(
        [IDL.Text],
        [IDL.Text, IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text))],
        [],
      ),
    'getFeedSummary' : IDL.Func([IDL.Text], [IDL.Text, IDL.Text], []),
    'getSampleFeed' : IDL.Func([], [Feed], ['query']),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'http_request_update' : IDL.Func([HttpRequest], [HttpResponse], []),
  });
  return Serve;
};
export const init = ({ IDL }) => { return []; };
