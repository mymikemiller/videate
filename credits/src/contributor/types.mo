import Buffer "mo:base/Buffer";

module {
  // Used to store the contents of the Contributor canister in stable types
  // between upgrades
  public type StableContributor = {
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
    #Ok : Nat64;
    #Err : {
      #NotAuthorized;
      #FeedNotFound;
      #MediaNotFound;
      #Other;
    };
  }
}
