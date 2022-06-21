import type { Principal } from '@dfinity/principal';
export type AssocList = [] | [[[Key, Profile], List]];
export interface Bio { 'name' : [] | [string] }
export interface Branch { 'left' : Trie, 'size' : bigint, 'right' : Trie }
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
export type Hash = number;
export interface Key { 'key' : Principal, 'hash' : Hash }
export interface Leaf { 'size' : bigint, 'keyvals' : AssocList }
export type List = [] | [[[Key, Profile], List]];
export interface Profile {
  'id' : Principal,
  'bio' : Bio,
  'feedKeys' : Array<string>,
}
export interface ProfileUpdate { 'bio' : Bio, 'feedKeys' : Array<string> }
export type Result = { 'ok' : null } |
  { 'err' : Error };
export type Result_1 = { 'ok' : Profile } |
  { 'err' : Error };
export type Trie = { 'branch' : Branch } |
  { 'leaf' : Leaf } |
  { 'empty' : null };
export interface _SERVICE {
  'addFeedKey' : (arg_0: string) => Promise<Result_1>,
  'buyNft' : (arg_0: string, arg_1: string) => Promise<BuyNftResult>,
  'create' : (arg_0: ProfileUpdate) => Promise<Result>,
  'delete' : () => Promise<Result>,
  'getAllProfiles' : () => Promise<Trie>,
  'getName' : (arg_0: Principal) => Promise<[] | [string]>,
  'read' : () => Promise<Result_1>,
  'update' : (arg_0: ProfileUpdate) => Promise<Result>,
}
