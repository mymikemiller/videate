import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Types "types";

actor Contributor {
  public type Bio = Types.Bio;
  public type Profile = Types.Profile;
  public type ProfileUpdate = Types.ProfileUpdate;
  public type Error = Types.Error;
  type StableContributor = Types.StableContributor;

  private func key(x: Principal) : Trie.Key<Principal> {
    return { key = x; hash = Principal.hash(x) };
  };

  private func asStable() : StableContributor = {
    // Map the (Principal, Profile) pairs from the unstable profiles trie into
    // a stable array of (Principal, Profile) pairs
    profileEntries = Iter.toArray(Trie.iter(profiles));
  };

  // This pattern uses `preupgrade` and `postupgrade` to allow `profiles` to be
  // stable even though Trie is not. See
  // https://sdk.dfinity.org/docs/language-guide/upgrades.html#_preupgrade_and_postupgrade_system_methods
  
  // Aplication state
  stable var stableContributor: StableContributor = { profileEntries = []; };

  // There is no Trie.fromArray, so we use a List as an intermediary
  var profiles : Trie.Trie<Principal, Profile> = Trie.fromList<Principal, Profile>(
    null,
    List.fromArray(
      Array.map<(Principal, Profile), (Trie.Key<Principal>, Profile)>(
        stableContributor.profileEntries,
        func ((principal: Principal, profile: Profile)) : (Trie.Key<Principal>, Profile) {
          return (
            key(principal),
            profile
          );
        }
      )
    ),
    0
  );

  system func preupgrade() {
      stableContributor := asStable();
  };

  system func postupgrade() {
      stableContributor := { profileEntries=[]; };
  };

  public func getAllProfiles(): async Trie.Trie<Principal, Profile> {
    return profiles;
  };

  private func getProfile(principal: Principal) : ?Profile {
    Debug.print("Looking for principal " # Principal.toText(principal));

    return Trie.find(
      profiles,          // Target trie
      key(principal),    // Key
      Principal.equal,   // Equality checker
    );
  };

  // Update the profile associated with the given principal, returning the new
  // profile. A null return value means we did not find a profile to update. 
  private func updateProfile(principal: Principal, profileUpdate : ProfileUpdate) : async ?Profile {
    // Associate user profile with their principal
    let userProfile: Profile = {
      id = principal;
      bio = profileUpdate.bio;
      feedUrls = profileUpdate.feedUrls;
    };

    switch (getProfile(principal)) {
      // Do not allow updates to profiles that haven't been created yet
      case null {
        return null;
      };
      case (? profile) {
        profiles := Trie.replace(
          profiles,
          key(principal),
          Principal.equal,
          ?userProfile
        ).0;
        return Option.make(userProfile);
      };
    };
  };

  // Public Application Interface

  // Add a feed url to the beginning of the list, or move it to the beginning
  // if it is already in the array
  public shared(msg) func addFeedUrl(feedUrl: Text) : async Result.Result<Profile, Error> {
    // Get caller principal
    let callerId = msg.caller;

    // Reject the AnonymousIdentity
    if(Principal.toText(callerId) == "2vxsx-fae") {
      return #err(#NotAuthorized);
    };

    switch (getProfile(callerId)) {
      case null {
        #err(#NotFound);
      };
      case (? existingProfile) {
        // Update the profile with the new feedUrls since we can't make
        // feedUrls mutable (it needs to be transfered via candid)
        let feedUrlsBuffer = Buffer.Buffer<Text>(existingProfile.feedUrls.size());
        feedUrlsBuffer.add(feedUrl); // Add the new url to the top of the list
        Iter.iterate(existingProfile.feedUrls.vals(), func(f: Text, _index: Nat) {
          if (f != feedUrl) { // Skip the new url so we don't store it twice
            feedUrlsBuffer.add(f);
          }
        });
        let newFeedUrls = feedUrlsBuffer.toArray();

        let profileUpdate: ProfileUpdate = {
          bio = existingProfile.bio;
          feedUrls = newFeedUrls;
        };

        let updatedProfile: ?Profile = await updateProfile(callerId, profileUpdate);
        return Result.fromOption(updatedProfile, #NotFound);
      };
    };
  };

  // Create a profile
  public shared(msg) func create(profile: ProfileUpdate) : async Result.Result<(), Error> {
    // Get caller principal
    let callerId = msg.caller;

    // Reject the AnonymousIdentity, which always has the value of "2vxsx-fae".
    // The AnonymousIdentity is one that any not-logged-in browser is, so it's
    // useless to have a user with that value.
    if(Principal.toText(callerId) == "2vxsx-fae") {
      return #err(#NotAuthorized);
    };

    //Associate user profile with their Principal
    let userProfile: Profile = {
      id = callerId;
      bio = profile.bio;
      feedUrls = profile.feedUrls;
    };

    let (newProfiles, existing) = Trie.put(
      profiles,          // Target trie
      key(callerId),     // Key
      Principal.equal,   // Equality checker
      userProfile
    );

    // If there is an original value, do not update
    switch(existing) {
      // If there are no matches, update profile
      case null {
        profiles := newProfiles;
        #ok(());
      };
      // Matches pattern of type - opt Profile
      case (? v) {
        #err(#AlreadyExists);
      }
    };
  };

  // Read profile
  public shared(msg) func read() : async Result.Result<Profile, Error> {
    // Get caller principal
    let callerId = msg.caller;

    // Reject the AnonymousIdentity
    if(Principal.toText(callerId) == "2vxsx-fae") {
      return #err(#NotAuthorized);
    };

    let profile = getProfile(callerId);
    return Result.fromOption(profile, #NotFound);
  };

  // Update profile
  public shared(msg) func update(profile : ProfileUpdate) : async Result.Result<(), Error> {
    // Get caller principal
    let callerId = msg.caller;

    // Reject the AnonymousIdentity
    if(Principal.toText(callerId) == "2vxsx-fae") {
      return #err(#NotAuthorized);
    };

    let newProfile = await updateProfile(callerId, profile);

    switch (newProfile) {
      case null {
      // Notify the caller that we did not find a profile to update
        #err(#NotFound);
      };
      case (? profile) {
        #ok(());
      };
    };
  };

  // Delete profile
  public shared(msg) func delete() : async Result.Result<(), Error> {
    // Get caller principal
    let callerId = msg.caller;

    // Reject the AnonymousIdentity
    if(Principal.toText(callerId) == "2vxsx-fae") {
      return #err(#NotAuthorized);
    };

    switch (getProfile(callerId)) {
      // Do not allow updates to profiles that haven't been created yet
      case null {
        #err(#NotFound);
      };
      case (? profile) {
        profiles := Trie.replace(
          profiles,
          key(callerId),
          Principal.equal,
          null              //Replace specified profile with null
        ).0;
        #ok(());
      };
    };
  };
};