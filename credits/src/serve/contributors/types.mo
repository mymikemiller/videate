import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
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

  public type ProfileResult = Result.Result<Profile, Error>;

  public type BuyNftResult = Result.Result<{
      #MintReceiptPart : NftTypes.MintReceiptPart;
      #TransferTransactionId : Nat;
    }, {
      #ApiError : NftTypes.ApiError;
      #SearchError : CreditsTypes.SearchError;
    }>;
};
