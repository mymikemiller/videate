import Buffer "mo:base/Buffer";
import NftTypes "../nft_db/types";
import CreditsTypes "../credits/types";

module {
  // Used to store the contents of the Contributors "database" in stable types
  // between upgrades
  public type StableContributors = {
      profileEntries: [(Principal, Profile)];
  };

  public type Bio = {
    name: ?Text;
  };

  public type Profile = {
    id: Principal;

    bio: Bio;
    feedKeys: [Text];
  };

  public type ProfileUpdate = {
    bio: Bio;
    feedKeys: [Text];
  };

  public type Error = {
    #NotFound;
    #AlreadyExists;
    #NotAuthorized;
  };

  public type BuyNftResult = {
    #Ok : {
      #MintReceiptPart : NftTypes.MintReceiptPart;
      #TransferTransactionId : Nat;
    };
    #Err : {
      #ApiError : NftTypes.ApiError;
      #SearchError : CreditsTypes.SearchError;
    };
  };
};
