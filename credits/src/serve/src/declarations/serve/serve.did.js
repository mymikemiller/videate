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
  const ApiError = IDL.Variant({
    'ZeroAddress' : IDL.Null,
    'InvalidTokenId' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'Other' : IDL.Null,
  });
  const Result__1 = IDL.Variant({ 'Ok' : IDL.Null, 'Err' : ApiError });
  const Bio = IDL.Record({ 'name' : IDL.Opt(IDL.Text) });
  const Profile = IDL.Record({
    'id' : IDL.Principal,
    'bio' : Bio,
    'feedKeys' : IDL.Vec(IDL.Text),
  });
  const Error = IDL.Variant({
    'NotFound' : IDL.Null,
    'NotAuthorized' : IDL.Null,
    'AlreadyExists' : IDL.Null,
  });
  const Result_1 = IDL.Variant({ 'ok' : Profile, 'err' : Error });
  const BuyNftResult = IDL.Variant({
    'Ok' : IDL.Nat64,
    'Err' : IDL.Variant({
      'MediaNotFound' : IDL.Null,
      'NotAuthorized' : IDL.Null,
      'FeedNotFound' : IDL.Null,
      'Other' : IDL.Null,
    }),
  });
  const ProfileUpdate__1 = IDL.Record({
    'bio' : Bio,
    'feedKeys' : IDL.Vec(IDL.Text),
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : Error });
  const TokenId = IDL.Nat64;
  const MetadataVal = IDL.Variant({
    'Nat64Content' : IDL.Nat64,
    'Nat32Content' : IDL.Nat32,
    'Nat8Content' : IDL.Nat8,
    'NatContent' : IDL.Nat,
    'Nat16Content' : IDL.Nat16,
    'BlobContent' : IDL.Vec(IDL.Nat8),
    'TextContent' : IDL.Text,
  });
  const MetadataKeyVal = IDL.Record({ 'key' : IDL.Text, 'val' : MetadataVal });
  const MetadataPurpose = IDL.Variant({
    'Preview' : IDL.Null,
    'Rendered' : IDL.Null,
  });
  const MetadataPart = IDL.Record({
    'data' : IDL.Vec(IDL.Nat8),
    'key_val_data' : IDL.Vec(MetadataKeyVal),
    'purpose' : MetadataPurpose,
  });
  const MetadataDesc__1 = IDL.Vec(MetadataPart);
  const ApiError__1 = IDL.Variant({
    'ZeroAddress' : IDL.Null,
    'InvalidTokenId' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'Other' : IDL.Null,
  });
  const MetadataResult = IDL.Variant({
    'Ok' : MetadataDesc__1,
    'Err' : ApiError__1,
  });
  const TokenId__1 = IDL.Nat64;
  const ExtendedMetadataResult = IDL.Variant({
    'Ok' : IDL.Record({
      'token_id' : TokenId__1,
      'metadata_desc' : MetadataDesc__1,
    }),
    'Err' : ApiError__1,
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
  const LogoResult = IDL.Record({ 'data' : IDL.Text, 'logo_type' : IDL.Text });
  const MetadataDesc = IDL.Vec(MetadataPart);
  const MintReceiptPart = IDL.Record({
    'id' : IDL.Nat,
    'token_id' : TokenId__1,
  });
  const MintReceipt = IDL.Variant({
    'Ok' : MintReceiptPart,
    'Err' : ApiError__1,
  });
  const OwnerResult = IDL.Variant({
    'Ok' : IDL.Principal,
    'Err' : ApiError__1,
  });
  const TxReceipt = IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : ApiError });
  const SearchError = IDL.Variant({
    'MediaNotFound' : IDL.Null,
    'FeedNotFound' : IDL.Null,
  });
  const MediaSearchResult = IDL.Variant({ 'Ok' : Media, 'Err' : SearchError });
  const InterfaceId = IDL.Variant({
    'Burn' : IDL.Null,
    'Mint' : IDL.Null,
    'Approval' : IDL.Null,
    'TransactionHistory' : IDL.Null,
    'TransferNotification' : IDL.Null,
  });
  const ProfileUpdate = IDL.Record({
    'bio' : Bio,
    'feedKeys' : IDL.Vec(IDL.Text),
  });
  const Serve = IDL.Service({
    'addFeed' : IDL.Func([IDL.Text, Feed], [IDL.Nat], []),
    'addNftCustodian' : IDL.Func([IDL.Principal], [Result__1], []),
    'addRequestedFeedKey' : IDL.Func([IDL.Text], [Result_1], []),
    'balanceOfDip721' : IDL.Func([IDL.Principal], [IDL.Nat64], ['query']),
    'buyNft' : IDL.Func([IDL.Text, IDL.Text], [BuyNftResult], []),
    'create' : IDL.Func([ProfileUpdate__1], [Result], []),
    'delete' : IDL.Func([], [Result], []),
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
    'getMaxLimitDip721' : IDL.Func([], [IDL.Nat16], ['query']),
    'getMetadataDip721' : IDL.Func([TokenId], [MetadataResult], ['query']),
    'getMetadataForUserDip721' : IDL.Func(
        [IDL.Principal],
        [ExtendedMetadataResult],
        [],
      ),
    'getSampleFeed' : IDL.Func([], [Feed], ['query']),
    'getTokenIdsForUserDip721' : IDL.Func(
        [IDL.Principal],
        [IDL.Vec(TokenId)],
        ['query'],
      ),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'http_request_update' : IDL.Func([HttpRequest], [HttpResponse], []),
    'logoDip721' : IDL.Func([], [LogoResult], ['query']),
    'mintDip721' : IDL.Func([IDL.Principal, MetadataDesc], [MintReceipt], []),
    'nameDip721' : IDL.Func([], [IDL.Text], ['query']),
    'ownerOfDip721' : IDL.Func([TokenId], [OwnerResult], ['query']),
    'read' : IDL.Func([], [Result_1], []),
    'safeTransferFromDip721' : IDL.Func(
        [IDL.Principal, IDL.Principal, TokenId],
        [TxReceipt],
        [],
      ),
    'setNftTokenId' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Opt(IDL.Nat64)],
        [MediaSearchResult],
        [],
      ),
    'supportedInterfacesDip721' : IDL.Func(
        [],
        [IDL.Vec(InterfaceId)],
        ['query'],
      ),
    'symbolDip721' : IDL.Func([], [IDL.Text], ['query']),
    'totalSupplyDip721' : IDL.Func([], [IDL.Nat64], ['query']),
    'transferFromDip721' : IDL.Func(
        [IDL.Principal, IDL.Principal, TokenId],
        [TxReceipt],
        [],
      ),
    'update' : IDL.Func([ProfileUpdate], [Result], []),
  });
  return Serve;
};
export const init = ({ IDL }) => { return [IDL.Principal]; };
