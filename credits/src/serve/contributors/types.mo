import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Time "mo:base/Time";
import NftTypes "../nft_db/types";
import CreditsTypes "../credits/types";

module {
  public type FeedKey = CreditsTypes.FeedKey;

  // Used to store the contents of the Contributors "database" in stable types
  // between upgrades
  public type StableContributors = {
    profileEntries : [(Principal, Profile)];
  };

  public type Download = {
    time : Time.Time;
    feedKey : CreditsTypes.FeedKey;
    episodeId : CreditsTypes.EpisodeID;
  };

  public type Bio = {
    name : ?Text;
  };

  public type Profile = {
    id : Principal;

    bio : Bio;
    feedKeys : [FeedKey]; // The feeds this user has indicated that they subscribe to. All keys in this array should be the lowercase version of feed.key.
    ownedFeedKeys : [FeedKey]; // The feeds this user created (owns) and manages. All keys in this array should be the lowercase version of feed.key.
    downloads : [Download]; // Every download performed by the user (or user's podcast app), in order
  };

  public type ProfileUpdate = {
    bio : Bio;
    feedKeys : [FeedKey];
    ownedFeedKeys : [FeedKey];
    downloads : [Download];
  };

  public type ContributorsError = {
    #NotFound;
    #AlreadyExists;
    #NotAuthorized;
  };

  public type ProfileResult = Result.Result<Profile, ContributorsError>;

  public type BuyNftResult = Result.Result<{ #MintReceiptPart : NftTypes.MintReceiptPart; #TransferTransactionId : Nat }, { #NftError : NftTypes.NftError; #CreditsError : CreditsTypes.CreditsError }>;
};
