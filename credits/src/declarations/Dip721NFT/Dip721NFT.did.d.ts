import type { Principal } from '@dfinity/principal';
export type ApiError = { 'ZeroAddress' : null } |
  { 'InvalidTokenId' : null } |
  { 'Unauthorized' : null } |
  { 'Other' : null };
export interface Dip721NFT {
  'addCustodian' : (arg_0: Principal) => Promise<Result>,
  'balanceOfDip721' : (arg_0: Principal) => Promise<bigint>,
  'getMaxLimitDip721' : () => Promise<number>,
  'getMetadataDip721' : (arg_0: TokenId) => Promise<MetadataResult>,
  'getMetadataForUserDip721' : (arg_0: Principal) => Promise<
      ExtendedMetadataResult
    >,
  'getTokenIdsForUserDip721' : (arg_0: Principal) => Promise<Array<TokenId>>,
  'logoDip721' : () => Promise<LogoResult>,
  'mintDip721' : (arg_0: Principal, arg_1: MetadataDesc) => Promise<
      MintReceipt
    >,
  'nameDip721' : () => Promise<string>,
  'ownerOfDip721' : (arg_0: TokenId) => Promise<OwnerResult>,
  'safeTransferFromDip721' : (
      arg_0: Principal,
      arg_1: Principal,
      arg_2: TokenId,
    ) => Promise<TxReceipt>,
  'supportedInterfacesDip721' : () => Promise<Array<InterfaceId>>,
  'symbolDip721' : () => Promise<string>,
  'test' : () => Promise<string>,
  'totalSupplyDip721' : () => Promise<bigint>,
  'transferFromDip721' : (
      arg_0: Principal,
      arg_1: Principal,
      arg_2: TokenId,
    ) => Promise<TxReceipt>,
}
export interface Dip721NonFungibleToken {
  'maxLimit' : number,
  'logo' : LogoResult,
  'name' : string,
  'symbol' : string,
}
export type ExtendedMetadataResult = {
    'Ok' : { 'token_id' : TokenId, 'metadata_desc' : MetadataDesc }
  } |
  { 'Err' : ApiError };
export type InterfaceId = { 'Burn' : null } |
  { 'Mint' : null } |
  { 'Approval' : null } |
  { 'TransactionHistory' : null } |
  { 'TransferNotification' : null };
export interface LogoResult { 'data' : string, 'logo_type' : string }
export type MetadataDesc = Array<MetadataPart>;
export interface MetadataKeyVal { 'key' : string, 'val' : MetadataVal }
export interface MetadataPart {
  'data' : Array<number>,
  'key_val_data' : Array<MetadataKeyVal>,
  'purpose' : MetadataPurpose,
}
export type MetadataPurpose = { 'Preview' : null } |
  { 'Rendered' : null };
export type MetadataResult = { 'Ok' : MetadataDesc } |
  { 'Err' : ApiError };
export type MetadataVal = { 'Nat64Content' : bigint } |
  { 'Nat32Content' : number } |
  { 'Nat8Content' : number } |
  { 'NatContent' : bigint } |
  { 'Nat16Content' : number } |
  { 'BlobContent' : Array<number> } |
  { 'TextContent' : string };
export type MintReceipt = { 'Ok' : MintReceiptPart } |
  { 'Err' : ApiError };
export interface MintReceiptPart { 'id' : bigint, 'token_id' : TokenId }
export type OwnerResult = { 'Ok' : Principal } |
  { 'Err' : ApiError };
export type Result = { 'Ok' : null } |
  { 'Err' : ApiError };
export type TokenId = bigint;
export type TxReceipt = { 'Ok' : bigint } |
  { 'Err' : ApiError };
export interface _SERVICE extends Dip721NFT {}
