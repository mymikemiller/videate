// The "database" of Videate Nfts. Implements the Dip721 standard.

// This file is set up like many in the Motoko base library, where the
// functions accept an Nft object instead of operating on the module's data.
// This is so that an object of this class can be made stable even though it
// contains non-stable types (the List of Nfts) since no functions operate on
// the member data. This is important to reduce upgrade time of canisters that
// use Nft objects, since they don't have to convert to/from a stable version.
// See https://forum.dfinity.org/t/clarification-on-stable-types-with-examples/11075/5

import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import List "mo:base/List";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Bool "mo:base/Bool";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Types "types";

module {
  public type Dip721NonFungibleToken = Types.Dip721NonFungibleToken;
  public type ApiError = Types.ApiError;
  public type Result<S, E> = Types.Result<S, E>;
  public type OwnerResult = Types.OwnerResult;
  public type TxReceipt =  Types.Result<Nat, ApiError>;
  public type TransactionId = Types.TransactionId;
  public type TokenId = Types.TokenId;
  public type InterfaceId = Types.InterfaceId;
  public type LogoResult = Types.LogoResult;
  public type ExtendedMetadataResult = Types.ExtendedMetadataResult;
  public type MetadataResult = Types.MetadataResult;
  public type MetadataDesc = Types.MetadataDesc;
  public type MetadataPart = Types.MetadataPart;
  public type MetadataPurpose = Types.MetadataPurpose;
  public type MetadataKeyVal = Types.MetadataKeyVal;
  public type MetadataVal = Types.MetadataVal;
  public type MintReceipt = Types.MintReceipt;
  public type MintReceiptPart = Types.MintReceiptPart;

  // After creating an instance of this class, call addCustodian on it to add
  // the identity that can manage the entire class. Usually this should be the
  // results of `dfx identity get-principal` so the class can be managed from
  // the command line.
  public class NftDb() = Self {
    public var transactionId: Types.TransactionId = 0;
    public var nfts = List.nil<Types.Nft>();
    public var custodians = List.nil<Principal>();
    public var logo : Types.LogoResult = {
      logo_type = "image/png";
      data = "";
    };
    public var name : Text = "Videate NFTs";
    public var symbol : Text = "VNFT";
    public var maxLimit : Nat16 = 0; // infinite

    // https://forum.dfinity.org/t/is-there-any-address-0-equivalent-at-dfinity-motoko/5445/3
    public let null_address : Principal = Principal.fromText("aaaaa-aa");
  };

  public func balanceOfDip721(nftDb: NftDb, user: Principal) : Nat64 {
    return Nat64.fromNat(
      List.size(
        List.filter(nftDb.nfts, func(token: Types.Nft) : Bool { token.owner == user })
      )
    );
  };

  public func ownerOfDip721(nftDb: NftDb, token_id: Types.TokenId) : Types.OwnerResult {
    let item = List.get(nftDb.nfts, Nat64.toNat(token_id));
    switch (item) {
      case (null) {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        return #Ok(token.owner);
      };
    };
  };

  public func safeTransferFromDip721(nftDb: NftDb, caller: Principal, from: Principal, to: Principal, token_id: Types.TokenId) : Types.TxReceipt {  
    if (to == nftDb.null_address) {
      return #Err(#ZeroAddress);
    } else {
      return transferFrom(nftDb, caller, from, to, token_id);
    };
  };

  public func transferFromDip721(nftDb: NftDb, caller: Principal, from: Principal, to: Principal, token_id: Types.TokenId) : Types.TxReceipt {
    return transferFrom(nftDb, caller, from, to, token_id);
  };

  public func transferFrom(nftDb: NftDb, caller: Principal, from: Principal, to: Principal, token_id: Types.TokenId) : Types.TxReceipt {
    let item = List.get(nftDb.nfts, Nat64.toNat(token_id));
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        if (
          caller != token.owner and
          not List.some(nftDb.custodians, func (custodian : Principal) : Bool { custodian == caller })
        ) {
          return #Err(#Unauthorized);
        } else if (Principal.notEqual(from, token.owner)) {
          return #Err(#Other("Attempt to transfer NFT from someone other than the owner."));
        } else {
          nftDb.nfts := List.map(nftDb.nfts, func (item : Types.Nft) : Types.Nft {
            if (item.id == token.id) {
              let update : Types.Nft = {
                owner = to;
                id = item.id;
                metadata = token.metadata;
              };
              return update;
            } else {
              return item;
            };
          });
          nftDb.transactionId += 1;
          return #Ok(nftDb.transactionId);   
        };
      };
    };
  };
  
  public func supportedInterfacesDip721() : [Types.InterfaceId] {
    return [#TransferNotification, #Burn, #Mint];
  };

  public func logoDip721(nftDb: NftDb) : Types.LogoResult {
    return nftDb.logo;
  };

  public func nameDip721(nftDb: NftDb) : Text {
    return nftDb.name;
  };

  public func symbolDip721(nftDb: NftDb) : Text {
    return nftDb.symbol;
  };

  public func totalSupplyDip721(nftDb: NftDb) : Nat64 {
    return Nat64.fromNat(
      List.size(nftDb.nfts)
    );
  };

  public func getMetadataDip721(nftDb: NftDb, token_id: Types.TokenId) : Types.MetadataResult {
    let item = List.get(nftDb.nfts, Nat64.toNat(token_id));
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        return #Ok(token.metadata);
      }
    };
  };

  public func getMaxLimitDip721(nftDb: NftDb) : Nat16 {
    return nftDb.maxLimit;
  };

  public func getMetadataForUserDip721(nftDb: NftDb, user: Principal) : Types.ExtendedMetadataResult {
    let item = List.find(nftDb.nfts, func(token: Types.Nft) : Bool { token.owner == user });
    switch (item) {
      case null {
        return #Err(#Other("No NFTs found for specified user"));
      };
      case (?token) {
        return #Ok({
          metadata_desc = token.metadata;
          token_id = token.id;
        });
      }
    };
  };

  public func getTokenIdsForUserDip721(nftDb: NftDb, user: Principal) : [Types.TokenId] {
    let items = List.filter(nftDb.nfts, func(token: Types.Nft) : Bool { token.owner == user });
    let tokenIds = List.map(items, func (item : Types.Nft) : Types.TokenId { item.id });
    return List.toArray(tokenIds);
  };

  public func mintDip721(nftDb: NftDb, caller: Principal, to: Principal, metadata: Types.MetadataDesc) : Types.MintReceipt {
    if (not List.some(nftDb.custodians, func (custodian : Principal) : Bool { custodian == caller })) {
      return #Err(#Other("Nft module is uninitialized"));
    };

    let newId = Nat64.fromNat(List.size(nftDb.nfts));
    let newNft : Types.Nft = {
      owner = to;
      id = newId;
      metadata = metadata;
    };

    nftDb.nfts := List.push(newNft, nftDb.nfts);

    nftDb.transactionId += 1;

    return #Ok({
      token_id = newId;
      id = nftDb.transactionId;
    });
  };

  public func isInitialized(nftDb: NftDb): Bool {    
    return nftDb.transactionId > 0 or List.size(nftDb.nfts) > 0 or List.size(nftDb.custodians) > 0
  };

  public func addCustodian(nftDb: NftDb, caller: Principal, newCustodian: Principal) : Result<(), ApiError> {
    // Once we've been initialized, only current custodians can add a new
    // custodian. Note that we allow anyone (usually the deployer since the
    // initalize call should be done immediately after deploying or else there
    // won't be a custodian and none of the functions in this class will work)
    // to specify the first custodian, usually the identity for their dfx (the
    // caller of serveActor.initialize()) so they can manage this class via the
    // console.
    if (isInitialized(nftDb) and not List.some(nftDb.custodians, func (custodian : Principal) : Bool { custodian == caller })) {
      return #Err(#Unauthorized);
    };

    // Add the new custodian if it's not already in the list
    if (not List.some(nftDb.custodians, func (custodian : Principal) : Bool { custodian == newCustodian })) {
      nftDb.custodians := List.push(newCustodian, nftDb.custodians);
    };

    return #Ok();
  };
};
