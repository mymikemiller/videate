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
    feedKeys: [Text]; // The feeds this user has indicated that they subscribe to
    ownedFeedKeys: [Text]; // The feeds this user created (owns) and manages
  };

  public type ProfileUpdate = {
    bio: Bio;
    feedKeys: [Text];
    ownedFeedKeys: [Text];
  };

  public type ContributorsError = {
    #NotFound;
    #AlreadyExists;
    #NotAuthorized;
  };

  public type ProfileResult = Result.Result<Profile, ContributorsError>;

  public type BuyNftResult = Result.Result<{
      #MintReceiptPart : NftTypes.MintReceiptPart;
      #TransferTransactionId : Nat;
    }, {
      #NftError : NftTypes.NftError;
      #CreditsError : CreditsTypes.CreditsError;
    }>;
};
