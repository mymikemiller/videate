import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type ApiError = { 'ZeroAddress' : null } |
  { 'InvalidTokenId' : null } |
  { 'Unauthorized' : null } |
  { 'Other' : null };
export type ApiError__1 = { 'ZeroAddress' : null } |
  { 'InvalidTokenId' : null } |
  { 'Unauthorized' : null } |
  { 'Other' : null };
export type ApiError__2 = { 'ZeroAddress' : null } |
  { 'InvalidTokenId' : null } |
  { 'Unauthorized' : null } |
  { 'Other' : null };
export interface Bio { 'name' : [] | [string] }
export type BuyNftResult = {
    'Ok' : { 'MintReceiptPart' : MintReceiptPart } |
      { 'TransferTransactionId' : bigint }
  } |
  { 'Err' : { 'ApiError' : ApiError__1 } | { 'SearchError' : SearchError } };
export type Error = { 'NotFound' : null } |
  { 'NotAuthorized' : null } |
  { 'AlreadyExists' : null };
export type ExtendedMetadataResult = {
    'Ok' : { 'token_id' : TokenId__1, 'metadata_desc' : MetadataDesc__1 }
  } |
  { 'Err' : ApiError__1 };
export interface Feed {
  'title' : string,
  'link' : string,
  'description' : string,
  'email' : string,
  'author' : string,
  'imageUrl' : string,
  'mediaList' : Array<Media>,
  'subtitle' : string,
}
export type HeaderField = [string, string];
export interface HttpRequest {
  'url' : string,
  'method' : string,
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
}
export interface HttpResponse {
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
  'streaming_strategy' : [] | [StreamingStrategy],
  'status_code' : number,
}
export type InterfaceId = { 'Burn' : null } |
  { 'Mint' : null } |
  { 'Approval' : null } |
  { 'TransactionHistory' : null } |
  { 'TransferNotification' : null };
export interface LogoResult { 'data' : string, 'logo_type' : string }
export interface Media {
  'uri' : string,
  'title' : string,
  'lengthInBytes' : bigint,
  'source' : Source,
  'etag' : string,
  'description' : string,
  'nftTokenId' : [] | [bigint],
  'durationInMicroseconds' : bigint,
}
export interface Media__1 {
  'uri' : string,
  'title' : string,
  'lengthInBytes' : bigint,
  'source' : Source,
  'etag' : string,
  'description' : string,
  'nftTokenId' : [] | [bigint],
  'durationInMicroseconds' : bigint,
}
export type MetadataDesc = Array<MetadataPart>;
export type MetadataDesc__1 = Array<MetadataPart>;
export interface MetadataKeyVal { 'key' : string, 'val' : MetadataVal }
export interface MetadataPart {
  'data' : Array<number>,
  'key_val_data' : Array<MetadataKeyVal>,
  'purpose' : MetadataPurpose,
}
export type MetadataPurpose = { 'Preview' : null } |
  { 'Rendered' : null };
export type MetadataResult = { 'Ok' : MetadataDesc__1 } |
  { 'Err' : ApiError__1 };
export type MetadataVal = { 'Nat64Content' : bigint } |
  { 'Nat32Content' : number } |
  { 'Nat8Content' : number } |
  { 'NatContent' : bigint } |
  { 'Nat16Content' : number } |
  { 'BlobContent' : Array<number> } |
  { 'TextContent' : string };
export type MintReceipt = { 'Ok' : MintReceiptPart } |
  { 'Err' : ApiError__1 };
export interface MintReceiptPart { 'id' : bigint, 'token_id' : TokenId__1 }
export type OwnerResult = { 'Ok' : Principal } |
  { 'Err' : ApiError__1 };
export interface Platform { 'id' : string, 'uri' : string }
export interface Profile {
  'id' : Principal,
  'bio' : Bio,
  'feedKeys' : Array<string>,
}
export interface ProfileUpdate { 'bio' : Bio, 'feedKeys' : Array<string> }
export interface ProfileUpdate__1 { 'bio' : Bio, 'feedKeys' : Array<string> }
export type Result = { 'ok' : null } |
  { 'err' : Error };
export type Result_1 = { 'ok' : Profile } |
  { 'err' : Error };
export type Result__1 = { 'Ok' : null } |
  { 'Err' : ApiError__2 };
export type SearchError = { 'MediaNotFound' : null } |
  { 'FeedNotFound' : null };
export interface Serve {
  'addFeed' : ActorMethod<[string, Feed], bigint>,
  'addNftCustodian' : ActorMethod<[Principal], Result__1>,
  'addRequestedFeedKey' : ActorMethod<[string], Result_1>,
  'balanceOfDip721' : ActorMethod<[Principal], bigint>,
  'buyNft' : ActorMethod<[string, Media__1], BuyNftResult>,
  'createContributor' : ActorMethod<[ProfileUpdate__1], Result>,
  'deleteContributor' : ActorMethod<[], Result>,
  'deleteFeed' : ActorMethod<[string], undefined>,
  'getAllFeedKeys' : ActorMethod<[], Array<string>>,
  'getAllFeedMediaDetails' : ActorMethod<
    [],
    Array<[string, Array<[string, string]>]>,
  >,
  'getAllFeedSummaries' : ActorMethod<[], Array<[string, string]>>,
  'getAllFeeds' : ActorMethod<[], Array<[string, Feed]>>,
  'getContributorName' : ActorMethod<[Principal], [] | [string]>,
  'getFeed' : ActorMethod<[string], [] | [Feed]>,
  'getFeedMediaDetails' : ActorMethod<
    [string],
    [string, Array<[string, string]>],
  >,
  'getFeedSummary' : ActorMethod<[string], [string, string]>,
  'getMaxLimitDip721' : ActorMethod<[], number>,
  'getMetadataDip721' : ActorMethod<[TokenId], MetadataResult>,
  'getMetadataForUserDip721' : ActorMethod<[Principal], ExtendedMetadataResult>,
  'getSampleFeed' : ActorMethod<[], Feed>,
  'getTokenIdsForUserDip721' : ActorMethod<[Principal], Array<TokenId>>,
  'http_request' : ActorMethod<[HttpRequest], HttpResponse>,
  'http_request_update' : ActorMethod<[HttpRequest], HttpResponse>,
  'initializeNft' : ActorMethod<[], Result__1>,
  'logoDip721' : ActorMethod<[], LogoResult>,
  'mintDip721' : ActorMethod<[Principal, MetadataDesc], MintReceipt>,
  'nameDip721' : ActorMethod<[], string>,
  'ownerOfDip721' : ActorMethod<[TokenId], OwnerResult>,
  'readContributor' : ActorMethod<[], Result_1>,
  'safeTransferFromDip721' : ActorMethod<
    [Principal, Principal, TokenId],
    TxReceipt,
  >,
  'supportedInterfacesDip721' : ActorMethod<[], Array<InterfaceId>>,
  'symbolDip721' : ActorMethod<[], string>,
  'totalSupplyDip721' : ActorMethod<[], bigint>,
  'transferFromDip721' : ActorMethod<
    [Principal, Principal, TokenId],
    TxReceipt,
  >,
  'updateContributor' : ActorMethod<[ProfileUpdate], Result>,
}
export interface Source {
  'id' : string,
  'uri' : string,
  'platform' : Platform,
  'releaseDate' : string,
}
export interface StreamingCallbackHttpResponse {
  'token' : Token,
  'body' : Array<number>,
}
export type StreamingStrategy = {
    'Callback' : { 'token' : Token, 'callback' : [Principal, string] }
  };
export type Token = {};
export type TokenId = bigint;
export type TokenId__1 = bigint;
export type TxReceipt = { 'Ok' : bigint } |
  { 'Err' : ApiError };
export interface _SERVICE extends Serve {}
