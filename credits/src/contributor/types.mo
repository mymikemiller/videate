import Buffer "mo:base/Buffer";
import List "mo:base/List";

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
    feedUrls: [Text];
  };

  public type ProfileUpdate = {
    bio: Bio;
    feedUrls: [Text];
  };

  public type Error = {
    #NotFound;
    #AlreadyExists;
    #NotAuthorized;
  };
}