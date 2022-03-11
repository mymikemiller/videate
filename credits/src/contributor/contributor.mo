import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

actor Contributor {
  type Bio = {
    name: ?Text;
  };

  type Profile = {
    bio: Bio;
    id: Principal;
  };

  type ProfileUpdate = {
    bio: Bio;
  };

  type Error = {
    #NotFound;
    #AlreadyExists;
    #NotAuthorized;
  };

  // Aplication state
  stable var profiles : Trie.Trie<Principal, Profile> = Trie.empty();

  // Application interface

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
      bio = profile.bio;
      id = callerId;
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

    let result = Trie.find(
      profiles,          // Target trie
      key(callerId),     // Key
      Principal.equal,   // Equality checker
    );
    return Result.fromOption(result, #NotFound);
  };

  // Update profile
  public shared(msg) func update(profile : ProfileUpdate) : async Result.Result<(), Error> {
    // Get caller principal
    let callerId = msg.caller;

    // Reject the AnonymousIdentity
    if(Principal.toText(callerId) == "2vxsx-fae") {
      return #err(#NotAuthorized);
    };

    // Associate user profile with their principal
    let userProfile: Profile = {
        bio = profile.bio;
        id = callerId;
    };
    
    let result = Trie.find(
      profiles,
      key(callerId),
      Principal.equal
    );

    switch (result) {
      // Do not allow updates to profiles that haven't been created yet
      case null {
        #err(#NotFound);
      };
      case (? v) {
        profiles := Trie.replace(
          profiles,
          key(callerId),
          Principal.equal,
          ?userProfile
        ).0;
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

    let result = Trie.find(
      profiles,
      key(callerId),
      Principal.equal
    );

    switch (result) {
      // Do not allow updates to profiles that haven't been created yet
      case null {
        #err(#NotFound);
      };
      case (? v) {
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

  private func key(x: Principal) : Trie.Key<Principal> {
    return { key = x; hash = Principal.hash(x) };
  };
};
