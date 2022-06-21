import type { Principal } from '@dfinity/principal';
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
export interface Platform { 'id' : string, 'uri' : string }
export interface Serve {
  'addFeed' : (arg_0: string, arg_1: Feed) => Promise<bigint>,
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
  'getSampleFeed' : () => Promise<Feed>,
  'http_request' : (arg_0: HttpRequest) => Promise<HttpResponse>,
  'http_request_update' : (arg_0: HttpRequest) => Promise<HttpResponse>,
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
export interface _SERVICE extends Serve {}
