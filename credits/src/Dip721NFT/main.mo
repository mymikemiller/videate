import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import List "mo:base/List";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";
import Types "./types";

shared actor class Dip721NFT(custodian: Principal, init : Types.Dip721NonFungibleToken) = Self {
  stable var transactionId: Types.TransactionId = 0;
  stable var nfts = List.nil<Types.Nft>();
  stable var custodians = List.make<Principal>(custodian);
  stable var logo : Types.LogoResult = init.logo;
  stable var name : Text = init.name;
  stable var symbol : Text = init.symbol;
  stable var maxLimit : Nat16 = init.maxLimit;

  // https://forum.dfinity.org/t/is-there-any-address-0-equivalent-at-dfinity-motoko/5445/3
  let null_address : Principal = Principal.fromText("aaaaa-aa");

  public query func balanceOfDip721(user: Principal) : async Nat64 {
    return Nat64.fromNat(
      List.size(
        List.filter(nfts, func(token: Types.Nft) : Bool { token.owner == user })
      )
    );
  };

  public query func ownerOfDip721(token_id: Types.TokenId) : async Types.OwnerResult {
    Debug.print("in ownerOfDip721");
    Debug.print("looking for nft at index (token_id) " # Nat64.toText(token_id));
    Debug.print("toNat: " # Nat.toText(Nat64.toNat(token_id)));

    Debug.print("FULL LIST:");
    Debug.print(debug_show(nfts));

    let item = List.get(nfts, Nat64.toNat(token_id));
    switch (item) {
      case (null) {
        Debug.print("no token");
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        Debug.print("found token:");
        Debug.print(debug_show(token));
        return #Ok(token.owner);
      };
    };
  };

  public shared({ caller }) func safeTransferFromDip721(from: Principal, to: Principal, token_id: Types.TokenId) : async Types.TxReceipt {  
    if (to == null_address) {
      return #Err(#ZeroAddress);
    } else {
      return transferFrom(from, to, token_id, caller);
    };
  };

  public shared({ caller }) func transferFromDip721(from: Principal, to: Principal, token_id: Types.TokenId) : async Types.TxReceipt {
    return transferFrom(from, to, token_id, caller);
  };

  func transferFrom(from: Principal, to: Principal, token_id: Types.TokenId, caller: Principal) : Types.TxReceipt {
    let item = List.get(nfts, Nat64.toNat(token_id));
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        if (
          caller != token.owner and
          not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })
        ) {
          return #Err(#Unauthorized);
        } else if (Principal.notEqual(from, token.owner)) {
          return #Err(#Other);
        } else {
          nfts := List.map(nfts, func (item : Types.Nft) : Types.Nft {
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
          transactionId += 1;
          return #Ok(transactionId);   
        };
      };
    };
  };

  public query func supportedInterfacesDip721() : async [Types.InterfaceId] {
    return [#TransferNotification, #Burn, #Mint];
  };

  public query func logoDip721() : async Types.LogoResult {
    return logo;
  };

  public query func nameDip721() : async Text {
    return name;
  };

  public query func symbolDip721() : async Text {
    return symbol;
  };

  public query func totalSupplyDip721() : async Nat64 {
    return Nat64.fromNat(
      List.size(nfts)
    );
  };

  public query func getMetadataDip721(token_id: Types.TokenId) : async Types.MetadataResult {
    let item = List.get(nfts, Nat64.toNat(token_id));
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        return #Ok(token.metadata);
      }
    };
  };

  public query func getMaxLimitDip721() : async Nat16 {
    return maxLimit;
  };

  public func getMetadataForUserDip721(user: Principal) : async Types.ExtendedMetadataResult {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.owner == user });
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

  public query func getTokenIdsForUserDip721(user: Principal) : async [Types.TokenId] {
    let items = List.filter(nfts, func(token: Types.Nft) : Bool { token.owner == user });
    let tokenIds = List.map(items, func (item : Types.Nft) : Types.TokenId { item.id });
    return List.toArray(tokenIds);
  };

  // public shared({ caller }) func mintDip721(to: Principal, metadata: Types.MetadataDesc) : async Types.MintReceipt {
  //   Debug.print("1. got into mintDip721.");
  //   Debug.trap("stopping here");
  //   Debug.print("caller: " # debug_show(caller));
  //   Debug.print("custodians: " # debug_show(custodians));
  //   if (not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })) {
  //     Debug.print("2");
  //     return #Err(#Unauthorized);
  //   };
  //   Debug.print("3");

  //   let newId = Nat64.fromNat(List.size(nfts));
  //   Debug.print("4");
  //   let nft : Types.Nft = {
  //     owner = to;
  //     id = newId;
  //     metadata = metadata;
  //   };
  //   Debug.print("5");

  //   nfts := List.push(nft, nfts);
  //   Debug.print("6");

  //   transactionId += 1;
  //   Debug.print("7");

  //   let result = #Ok({
  //     token_id = newId;
  //     id = transactionId;
  //   });

  //   Debug.print("returning result:");
  //   Debug.print(debug_show(result));

  //   return result;
  // };

  public shared({ caller }) func mintDip721(to: Principal, metadata: Types.MetadataDesc) : async Types.MintReceipt {
    Debug.print("1. got into mintDip721.");
    Debug.print("caller: " # debug_show(caller));
    Debug.print("custodians: " # debug_show(custodians));
    if (not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })) {
      Debug.print("2");
      return #Err(#Unauthorized);
    };
    Debug.print("3");

    let newId = Nat64.fromNat(List.size(nfts));
    Debug.print("4");
    Debug.print("Setting owner of " # Nat64.toText(newId) # " to " # Principal.toText(to));
    let nft : Types.Nft = {
      owner = to;
      id = newId;
      metadata = metadata;
    };
    Debug.print("5");

    nfts := List.append(nfts, List.make(nft)); // THIS WAS A BUG should not have been push, that adds to the beginning so the token_id no longer matches the index
    Debug.print("6");

    transactionId += 1; 
    Debug.print("7");

    let result = #Ok({
      token_id = newId;
      id = transactionId;
    });

    Debug.print("returning result:");
    Debug.print(debug_show(result));

    return result;
  };

  public shared({ caller }) func addCustodian(newCustodian: Principal) : async Types.Result<(), Types.ApiError> {
    // Only current custodians can add a new custodian
    if (not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })) {
      return #Err(#Unauthorized);
    };

    // Add the new custodian if it's not already in the list
    if (not List.some(custodians, func (custodian : Principal) : Bool { custodian == newCustodian })) {
      custodians := List.push(newCustodian, custodians);
    };

    return #Ok();
  };

  public shared func test() : async Text {
    Debug.print("returning hello");
    return "hello";
  }
}
