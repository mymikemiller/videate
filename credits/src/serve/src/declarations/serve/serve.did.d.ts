import type { Principal } from '@dfinity/principal';
export type ApiError = { 'ZeroAddress' : null } |
  { 'InvalidTokenId' : null } |
  { 'Unauthorized' : null } |
  { 'Other' : null };
export type ApiError__1 = { 'ZeroAddress' : null } |
  { 'InvalidTokenId' : null } |
  { 'Unauthorized' : null } |
  { 'Other' : null };
export interface Bio { 'name' : [] | [string] }
export type BuyNftResult = { 'Ok' : bigint } |
  {
    'Err' : { 'MediaNotFound' : null } |
      { 'NotAuthorized' : null } |
      { 'FeedNotFound' : null } |
      { 'Other' : null }
  };
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
export type MediaSearchResult = { 'Ok' : Media } |
  { 'Err' : SearchError };
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
  { 'Err' : ApiError };
export type SearchError = { 'MediaNotFound' : null } |
  { 'FeedNotFound' : null };
export interface Serve {
  'addFeed' : (arg_0: string, arg_1: Feed) => Promise<bigint>,
  'addNftCustodian' : (arg_0: Principal) => Promise<Result__1>,
  'addRequestedFeedKey' : (arg_0: string) => Promise<Result_1>,
  'balanceOfDip721' : (arg_0: Principal) => Promise<bigint>,
  'buyNft' : (arg_0: string, arg_1: string) => Promise<BuyNftResult>,
  'create' : (arg_0: ProfileUpdate__1) => Promise<Result>,
  'delete' : () => Promise<Result>,
  'deleteFeed' : (arg_0: string) => Promise<undefined>,
  'getAllFeedKeys' : () => Promise<Array<string>>,
  'getAllFeedMediaDetails' : () => Promise<
      Array<[string, Array<[string, string]>]>
    >,
  'getAllFeedSummaries' : () => Promise<Array<[string, string]>>,
  'getAllFeeds' : () => Promise<Array<[string, Feed]>>,
  'getFeed' : (arg_0: string) => Promise<[] | [Feed]>,
  'getFeedMediaDetails' : (arg_0: string) => Promise<
      [string, Array<[string, string]>]
    >,
  'getFeedSummary' : (arg_0: string) => Promise<[string, string]>,
  'getMaxLimitDip721' : () => Promise<number>,
  'getMetadataDip721' : (arg_0: TokenId) => Promise<MetadataResult>,
  'getMetadataForUserDip721' : (arg_0: Principal) => Promise<
      ExtendedMetadataResult
    >,
  'getSampleFeed' : () => Promise<Feed>,
  'getTokenIdsForUserDip721' : (arg_0: Principal) => Promise<Array<TokenId>>,
  'http_request' : (arg_0: HttpRequest) => Promise<HttpResponse>,
  'http_request_update' : (arg_0: HttpRequest) => Promise<HttpResponse>,
  'logoDip721' : () => Promise<LogoResult>,
  'mintDip721' : (arg_0: Principal, arg_1: MetadataDesc) => Promise<
      MintReceipt
    >,
  'nameDip721' : () => Promise<string>,
  'ownerOfDip721' : (arg_0: TokenId) => Promise<OwnerResult>,
  'read' : () => Promise<Result_1>,
  'safeTransferFromDip721' : (
      arg_0: Principal,
      arg_1: Principal,
      arg_2: TokenId,
    ) => Promise<TxReceipt>,
  'setNftTokenId' : (
      arg_0: string,
      arg_1: string,
      arg_2: [] | [bigint],
    ) => Promise<MediaSearchResult>,
  'supportedInterfacesDip721' : () => Promise<Array<InterfaceId>>,
  'symbolDip721' : () => Promise<string>,
  'totalSupplyDip721' : () => Promise<bigint>,
  'transferFromDip721' : (
      arg_0: Principal,
      arg_1: Principal,
      arg_2: TokenId,
    ) => Promise<TxReceipt>,
  'update' : (arg_0: ProfileUpdate) => Promise<Result>,
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
