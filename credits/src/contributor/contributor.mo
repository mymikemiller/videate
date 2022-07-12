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
import Types "types";

import NftTypes "../Serve/nft_types";
import ServeTypes "../Serve/types";
// import NFT "ic:canisters/NFT";
// import NFT "ic:{cid on mainnet IC}"; // Switch to this when deploying to the IC

// public shared({ caller }) func mint(to: Principal, metadata: Types.MetadataDesc) : async Types.MintReceipt {

actor Contributor {
  // let cowsay = actor(“7igbu-3qaaa-aaaaa-qaapq-cai”): actor { cowsay: (Text) -> async Text };

  // let NFT = actor("rno2w-sqaaa-aaaaa-aaacq-cai"): actor { mint: (Principal, NFTTypes.MetadataDesc) -> async NFTTypes.MintReceipt };
  let Serve = actor("rrkah-fqaaa-aaaaa-aaaaq-cai"): 
    actor { 
      setNftTokenId: (feedKey: Text, episodeGuid: Text, tokenId: Nat64) -> async ServeTypes.MediaSearchResult;
      mintDip721: (to: Principal, metadata: NftTypes.MetadataDesc) -> async NftTypes.MintReceipt;
  };
  public type Bio = Types.Bio;
  public type Profile = Types.Profile;
  public type ProfileUpdate = Types.ProfileUpdate;
  public type Error = Types.Error;
  public type BuyNftResult = Types.BuyNftResult;
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
    return Trie.find(
      profiles,          // Target trie
      key(principal),    // Key
      Principal.equal,   // Equality checker
    );
  };

  public func getName(principal: Principal) : async ?Text {
    Debug.print("in getName. principal:");
    Debug.print(debug_show(principal));
    switch (getProfile(principal)) {
      case (null) null;
      case (? profile) {
        Debug.print("found profile");
        Debug.print(debug_show(profile));
        Debug.print(debug_show(profile.bio));
        Debug.print(debug_show(profile.bio.name));
        profile.bio.name;
      };
    };
  };

  // Update the profile associated with the given principal, returning the new
  // profile. A null return value means we did not find a profile to update. 
  private func updateProfile(principal: Principal, profileUpdate : ProfileUpdate) : async ?Profile {
    // Associate user profile with their principal
    let userProfile: Profile = {
      id = principal;
      bio = profileUpdate.bio;
      feedKeys = profileUpdate.feedKeys;
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

  // Add a feed key to the beginning of the list, or move it to the beginning
  // if it is already in the array
  public shared(msg) func addFeedKey(feedKey: Text) : async Result.Result<Profile, Error> {
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
        // Update the profile with the new feedKeys since we can't make
        // feedKeys mutable (it needs to be transfered via candid)
        let feedKeysBuffer = Buffer.Buffer<Text>(existingProfile.feedKeys.size());
        feedKeysBuffer.add(feedKey); // Add the new url to the top of the list
        Iter.iterate(existingProfile.feedKeys.vals(), func(f: Text, _index: Nat) {
          if (f != feedKey) { // Skip the new url so we don't store it twice
            feedKeysBuffer.add(f);
          }
        });
        let newFeedKeys = feedKeysBuffer.toArray();

        let profileUpdate: ProfileUpdate = {
          bio = existingProfile.bio;
          feedKeys = newFeedKeys;
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
      feedKeys = profile.feedKeys;
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

  public shared(msg) func buyNft(feedKey: Text, episodeGuid: Text) : async BuyNftResult {
    let callerId = msg.caller;
    let metadata: [NftTypes.MetadataPart] = [
      {
        purpose = #Rendered;
        key_val_data = [
          {
            key = "description"; 
            val = #TextContent ("Episode of a Videate podcast");
          },
          {
            key = "tag"; 
            val = #TextContent ("episode");
          },
          {
            key = "contentType";
            val = #TextContent ("text/plain");
          },
          {
            key = "locationType"; 
            val = #Nat8Content (4);
          }
        ];
        data = Text.encodeUtf8("https://rss.videate.org/" # feedKey # "/" # episodeGuid);
      }
    ];
    Debug.print("Minting NFT " # feedKey # " " # episodeGuid);
    Debug.print("callerId: " # debug_show(callerId));
    Debug.print("metadata: " # debug_show(metadata));
    let result = await Serve.mintDip721(callerId, metadata);
    Debug.print("Done minting.");

    switch(result) {
      case (#Ok(mintReceiptPart: NftTypes.MintReceiptPart)) {
        // Associate the Media with the new new tokenId
        let setNftResult = await Serve.setNftTokenId(feedKey, episodeGuid, mintReceiptPart.token_id);
        switch(setNftResult) {
          case (#Ok(media: ServeTypes.Media)) {
            return #Ok(mintReceiptPart.token_id);
          };
          case (#Err(e)) {
            switch (e) {
              case (#FeedNotFound) {
                return #Err(#FeedNotFound);
              };
              case (#MediaNotFound) {
                return #Err(#MediaNotFound);
              };
            };
          };
        };
      };
      case (#Err(e)) {
        Debug.print("result:");
        Debug.print(debug_show(result));
        switch(e) {
          case (#Unauthorized) {
            return #Err(#NotAuthorized);
          };
          case (#InvalidTokenId) {
            return #Err(#Other);
          };
          case (#ZeroAddress) {
            return #Err(#Other);
          };
          case (#Other) {
            return #Err(#Other);
          };
        };
      };
    };
  };
};
