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
import NftTypes "./nft_types";

module {
  public type Dip721NonFungibleToken = NftTypes.Dip721NonFungibleToken;
  public type ApiError = NftTypes.ApiError;
  public type Result<S, E> = NftTypes.Result<S, E>;
  public type OwnerResult = NftTypes.OwnerResult;
  public type TxReceipt =  NftTypes.Result<Nat, ApiError>;
  public type TransactionId = NftTypes.TransactionId;
  public type TokenId = NftTypes.TokenId;
  public type InterfaceId = NftTypes.InterfaceId;
  public type LogoResult = NftTypes.LogoResult;
  public type ExtendedMetadataResult = NftTypes.ExtendedMetadataResult;
  public type MetadataResult = NftTypes.MetadataResult;
  public type MetadataDesc = NftTypes.MetadataDesc;
  public type MetadataPart = NftTypes.MetadataPart;
  public type MetadataPurpose = NftTypes.MetadataPurpose;
  public type MetadataKeyVal = NftTypes.MetadataKeyVal;
  public type MetadataVal = NftTypes.MetadataVal;
  public type MintReceipt = NftTypes.MintReceipt;
  public type MintReceiptPart = NftTypes.MintReceiptPart;

  public class Nft(custodian: Principal) = Self {
    public var transactionId: NftTypes.TransactionId = 0;
    public var nfts = List.nil<NftTypes.Nft>();
    public var custodians = List.make<Principal>(custodian);
    public var logo : NftTypes.LogoResult = {
      logo_type = "image/png";
      data = "";
    };
    public var name : Text = "Videate NFTs";
    public var symbol : Text = "VNFT";
    public var maxLimit : Nat16 = 0; // infinite

    // https://forum.dfinity.org/t/is-there-any-address-0-equivalent-at-dfinity-motoko/5445/3
    public let null_address : Principal = Principal.fromText("aaaaa-aa");
  };

  public func balanceOfDip721(nft: Nft, user: Principal) : Nat64 {
    return Nat64.fromNat(
      List.size(
        List.filter(nft.nfts, func(token: NftTypes.Nft) : Bool { token.owner == user })
      )
    );
  };

  public func ownerOfDip721(nft: Nft, token_id: NftTypes.TokenId) : NftTypes.OwnerResult {
    Debug.print("in ownerOfDip721 for token_id " # debug_show(token_id));
    let item = List.get(nft.nfts, Nat64.toNat(token_id));
    switch (item) {
      case (null) {
        Debug.print("invalid token id");
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        Debug.print("valid token");
        Debug.print("owner:");
        Debug.print(debug_show(token.owner));
        return #Ok(token.owner);
      };
    };
  };

  public func safeTransferFromDip721(nft: Nft, caller: Principal, from: Principal, to: Principal, token_id: NftTypes.TokenId) : NftTypes.TxReceipt {  
    if (to == nft.null_address) {
      return #Err(#ZeroAddress);
    } else {
      return transferFrom(nft, from, to, token_id, caller);
    };
  };

  public func transferFromDip721(nft: Nft, caller: Principal, from: Principal, to: Principal, token_id: NftTypes.TokenId) : NftTypes.TxReceipt {
    return transferFrom(nft, from, to, token_id, caller);
  };

  public func transferFrom(nft: Nft, from: Principal, to: Principal, token_id: NftTypes.TokenId, caller: Principal) : NftTypes.TxReceipt {
    let item = List.get(nft.nfts, Nat64.toNat(token_id));
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        if (
          caller != token.owner and
          not List.some(nft.custodians, func (custodian : Principal) : Bool { custodian == caller })
        ) {
          return #Err(#Unauthorized);
        } else if (Principal.notEqual(from, token.owner)) {
          return #Err(#Other);
        } else {
          nft.nfts := List.map(nft.nfts, func (item : NftTypes.Nft) : NftTypes.Nft {
            if (item.id == token.id) {
              let update : NftTypes.Nft = {
                owner = to;
                id = item.id;
                metadata = token.metadata;
              };
              return update;
            } else {
              return item;
            };
          });
          nft.transactionId += 1;
          return #Ok(nft.transactionId);   
        };
      };
    };
  };
  
  public func supportedInterfacesDip721() : [NftTypes.InterfaceId] {
    return [#TransferNotification, #Burn, #Mint];
  };

  public func logoDip721(nft: Nft) : NftTypes.LogoResult {
    return nft.logo;
  };

  public func nameDip721(nft: Nft) : Text {
    return nft.name;
  };

  public func symbolDip721(nft: Nft) : Text {
    return nft.symbol;
  };

  public func totalSupplyDip721(nft: Nft) : Nat64 {
    return Nat64.fromNat(
      List.size(nft.nfts)
    );
  };

  public func getMetadataDip721(nft: Nft, token_id: NftTypes.TokenId) : NftTypes.MetadataResult {
    let item = List.get(nft.nfts, Nat64.toNat(token_id));
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        return #Ok(token.metadata);
      }
    };
  };

  public func getMaxLimitDip721(nft: Nft) : Nat16 {
    return nft.maxLimit;
  };

  public func getMetadataForUserDip721(nft: Nft, user: Principal) : NftTypes.ExtendedMetadataResult {
    let item = List.find(nft.nfts, func(token: NftTypes.Nft) : Bool { token.owner == user });
    switch (item) {
      case null {
        return #Err(#Other);
      };
      case (?token) {
        return #Ok({
          metadata_desc = token.metadata;
          token_id = token.id;
        });
      }
    };
  };

  public func getTokenIdsForUserDip721(nft: Nft, user: Principal) : [NftTypes.TokenId] {
    let items = List.filter(nft.nfts, func(token: NftTypes.Nft) : Bool { token.owner == user });
    let tokenIds = List.map(items, func (item : NftTypes.Nft) : NftTypes.TokenId { item.id });
    return List.toArray(tokenIds);
  };

  public func mintDip721(nft: Nft, caller: Principal, to: Principal, metadata: NftTypes.MetadataDesc) : NftTypes.MintReceipt {
    if (not List.some(nft.custodians, func (custodian : Principal) : Bool { custodian == caller })) {
      return #Err(#Unauthorized);
    };

    let newId = Nat64.fromNat(List.size(nft.nfts));
    let newNft : NftTypes.Nft = {
      owner = to;
      id = newId;
      metadata = metadata;
    };

    nft.nfts := List.push(newNft, nft.nfts);

    nft.transactionId += 1;

    return #Ok({
      token_id = newId;
      id = nft.transactionId;
    });
  };
};
