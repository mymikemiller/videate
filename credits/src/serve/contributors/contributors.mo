import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Utils "../utils";
import Types "types";
import NftTypes "../nft_db/types";
import CreditsTypes "../credits/types";
import ServeTypes "../types";

module {
  public type Bio = Types.Bio;
  public type Profile = Types.Profile;
  public type ProfileResult = Types.ProfileResult;
  public type ProfileUpdate = Types.ProfileUpdate;
  public type ContributorsError = Types.ContributorsError;
  public type BuyNftResult = Types.BuyNftResult;
  public type StableContributors = Types.StableContributors;
  public type Download = Types.Download;
  public type FeedKey = Types.FeedKey;

  private func key(x : Principal) : Trie.Key<Principal> {
    return { key = x; hash = Principal.hash(x) };
  };

  public class Contributors(init : StableContributors) {
    // There is no Trie.fromArray, so we use a List as an intermediary
    var profiles : Trie.Trie<Principal, Profile> = Trie.fromList<Principal, Profile>(
      null,
      List.fromArray(
        Array.map<(Principal, Profile), (Trie.Key<Principal>, Profile)>(
          init.profileEntries,
          func((principal : Principal, profile : Profile)) : (Trie.Key<Principal>, Profile) {
            return (
              key(principal),
              profile,
            );
          },
        )
      ),
      0,
    );

    public func asStable() : StableContributors = {
      // Map the (Principal, Profile) pairs from the unstable profiles trie into
      // a stable array of (Principal, Profile) pairs
      profileEntries = Iter.toArray(Trie.iter(profiles));
    };

    public func getAllProfiles() : Trie.Trie<Principal, Profile> {
      return profiles;
    };

    private func getProfile(principal : Principal) : ?Profile {
      return Trie.find(
        profiles, // Target trie
        key(principal), // Key
        Principal.equal, // Equality checker
      );
    };

    public func getName(principal : Principal) : ?Text {
      switch (getProfile(principal)) {
        case (null) {
          null;
        };
        case (?profile) {
          profile.bio.name;
        };
      };
    };

    public func getDownloads(principal : Principal) : ?[Download] {
      switch (getProfile(principal)) {
        case null null;
        case (?profile) {
          Option.make(profile.downloads);
        };
      };
    };

    // Update the profile associated with the given principal, returning the new
    // profile. A null return value means we did not find a profile to update.
    private func updateProfile(principal : Principal, profileUpdate : ProfileUpdate) : ?Profile {
      // Associate user profile with their principal
      let userProfile : Profile = {
        id = principal;
        bio = profileUpdate.bio;
        feedKeys = profileUpdate.feedKeys;
        ownedFeedKeys = profileUpdate.ownedFeedKeys;
        downloads = profileUpdate.downloads;
      };

      switch (getProfile(principal)) {
        // Do not allow updates to profiles that haven't been created yet
        case null {
          return null;
        };
        case (?profile) {
          profiles := Trie.replace(
            profiles,
            key(principal),
            Principal.equal,
            ?userProfile,
          ).0;
          return Option.make(userProfile);
        };
      };
    };

    // Public Application Interface

    // Add a feed key to the beginning of the list, or move it to the beginning
    // if it is already in the array
    public func addRequestedFeedKey(caller : Principal, feedKey : Text) : ProfileResult {
      // Reject the AnonymousIdentity
      if (Principal.toText(caller) == "2vxsx-fae") {
        return #err(#NotAuthorized);
      };

      switch (getProfile(caller)) {
        case null {
          #err(#NotFound);
        };
        case (?existingProfile) {
          // Update the profile with the new feedKeys since we can't make
          // feedKeys mutable (it needs to be transfered via candid)
          let feedKeyLowerCase = Utils.toLowercase(feedKey);
          let newFeedKeys = Utils.pushOrMoveToTop(existingProfile.feedKeys, feedKeyLowerCase);

          let profileUpdate : ProfileUpdate = {
            bio = existingProfile.bio;
            feedKeys = newFeedKeys;
            ownedFeedKeys = existingProfile.ownedFeedKeys;
            downloads = existingProfile.downloads;
          };

          let updatedProfile : ?Profile = updateProfile(caller, profileUpdate);
          return Result.fromOption(updatedProfile, #NotFound);
        };
      };
    };

    // Add a feed key to the list of feeds this user owns
    public func addOwnedFeedKey(caller : Principal, feedKey : FeedKey) : ProfileResult {
      // Reject the AnonymousIdentity
      if (Principal.toText(caller) == "2vxsx-fae") {
        return #err(#NotAuthorized);
      };

      switch (getProfile(caller)) {
        case null {
          #err(#NotFound);
        };
        case (?existingProfile) {
          // Update the profile with the new ownedFeedKeys since we can't make
          // ownedFeedKeys mutable (it needs to be transfered via candid)
          let newOwnedFeedKeys = Utils.pushOrMoveToTop(existingProfile.ownedFeedKeys, feedKey);

          let profileUpdate : ProfileUpdate = {
            bio = existingProfile.bio;
            feedKeys = existingProfile.feedKeys;
            ownedFeedKeys = newOwnedFeedKeys;
            downloads = existingProfile.downloads;
          };

          let updatedProfile : ?Profile = updateProfile(caller, profileUpdate);
          return Result.fromOption(updatedProfile, #NotFound);
        };
      };
    };

    // Return the list of feeds this user owns
    public func getOwnedFeedKeys(caller : Principal) : [Text] {
      switch (getProfile(caller)) {
        case null {
          return [];
        };
        case (?existingProfile) {
          return existingProfile.ownedFeedKeys;
        };
      };
    };

    // Remove the feed key from the list of feeds this user owns
    public func removeOwnedFeedKey(caller : Principal, feedKey : Text) : ProfileResult {
      // Reject the AnonymousIdentity
      if (Principal.toText(caller) == "2vxsx-fae") {
        return #err(#NotAuthorized);
      };

      switch (getProfile(caller)) {
        case null {
          #err(#NotFound);
        };
        case (?existingProfile) {
          // Update the profile with feedKey removed from ownedFeedKeys (we
          // can't make ownedFeedKeys mutable since it needs to be transfered
          // via candid)
          let feedKeyLowerCase = Utils.toLowercase(feedKey);
          let newOwnedFeedKeys = Utils.pushOrMoveToTop(existingProfile.ownedFeedKeys, feedKeyLowerCase);

          let profileUpdate : ProfileUpdate = {
            bio = existingProfile.bio;
            feedKeys = existingProfile.feedKeys;
            ownedFeedKeys = newOwnedFeedKeys;
            downloads = existingProfile.downloads;
          };

          let updatedProfile : ?Profile = updateProfile(caller, profileUpdate);
          return Result.fromOption(updatedProfile, #NotFound);
        };
      };
    };

    // Remove all owned feed keys from the given Contributor
    public func removeAllOwnedFeedKeys(caller : Principal) : ProfileResult {
      // Reject the AnonymousIdentity
      if (Principal.toText(caller) == "2vxsx-fae") {
        return #err(#NotAuthorized);
      };

      switch (getProfile(caller)) {
        case null {
          #err(#NotFound);
        };
        case (?existingProfile) {
          let profileUpdate : ProfileUpdate = {
            bio = existingProfile.bio;
            feedKeys = existingProfile.feedKeys;
            ownedFeedKeys = [];
            downloads = existingProfile.downloads;
          };

          let updatedProfile : ?Profile = updateProfile(caller, profileUpdate);
          return Result.fromOption(updatedProfile, #NotFound);
        };
      };
    };

    // Log a download for the given contributor
    public func logDownload(principal : Principal, download : Download) : ?() {
      switch (getProfile(principal)) {
        case null return null;
        case (?profile) {
          // Update the profile with modified downlaods array since we can't
          // make the downloads array mutable (it needs to be transfered via
          // candid)
          let downloadsBuffer = Buffer.Buffer<Download>(profile.downloads.size() + 1);
          Iter.iterate(
            profile.downloads.vals(),
            func(d : Download, _index : Nat) {
              downloadsBuffer.add(d);
            },
          );
          downloadsBuffer.add(download); // Add the new download to the end of the buffer
          let newDownloads = Buffer.toArray(downloadsBuffer);

          let profileUpdate : ProfileUpdate = {
            bio = profile.bio;
            feedKeys = profile.feedKeys;
            ownedFeedKeys = profile.ownedFeedKeys;
            downloads = newDownloads;
          };

          let updatedProfile : ?Profile = updateProfile(principal, profileUpdate);
          return if (updatedProfile == null) null else Option.make(());
        };
      };
    };

    // Create a profile
    public func create(caller : Principal, profile : ProfileUpdate) : Result.Result<(), ContributorsError> {
      // Reject the AnonymousIdentity, which always has the value of "2vxsx-fae".
      // The AnonymousIdentity is one that any not-logged-in browser is, so it's
      // useless to have a user with that value.
      if (Principal.toText(caller) == "2vxsx-fae") {
        return #err(#NotAuthorized);
      };

      // Associate user profile with their Principal
      let userProfile : Profile = {
        id = caller;
        bio = profile.bio;
        feedKeys = profile.feedKeys;
        ownedFeedKeys = profile.ownedFeedKeys;
        downloads = profile.downloads;
      };

      let (newProfiles, existing) = Trie.put(
        profiles, // Target trie
        key(caller), // Key
        Principal.equal, // Equality checker
        userProfile,
      );

      // If there is an original value, do not update
      switch (existing) {
        // If there are no matches, update profile
        case null {
          profiles := newProfiles;
          #ok(());
        };
        // Matches pattern of type - opt Profile
        case (?v) {
          #err(#AlreadyExists);
        };
      };
    };

    // Read profile
    public func read(caller : Principal) : ProfileResult {
      // Reject the AnonymousIdentity
      if (Principal.toText(caller) == "2vxsx-fae") {
        return #err(#NotAuthorized);
      };

      let profile = getProfile(caller);
      return Result.fromOption(profile, #NotFound);
    };

    // Update profile
    public func update(caller : Principal, profile : ProfileUpdate) : Result.Result<(), ContributorsError> {
      // Reject the AnonymousIdentity
      if (Principal.toText(caller) == "2vxsx-fae") {
        return #err(#NotAuthorized);
      };

      let newProfile = updateProfile(caller, profile);

      switch (newProfile) {
        case null {
          // Notify the caller that we did not find a profile to update
          #err(#NotFound);
        };
        case (?profile) {
          #ok(());
        };
      };
    };

    // Delete profile
    public func delete(caller : Principal) : Result.Result<(), ContributorsError> {
      // Reject the AnonymousIdentity
      if (Principal.toText(caller) == "2vxsx-fae") {
        return #err(#NotAuthorized);
      };

      switch (getProfile(caller)) {
        // Do not allow updates to profiles that haven't been created yet
        case null {
          #err(#NotFound);
        };
        case (?profile) {
          profiles := Trie.replace(
            profiles,
            key(caller),
            Principal.equal,
            null //Replace specified profile with null
          ).0;
          #ok(());
        };
      };
    };
  };
};
