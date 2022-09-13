// Ideally this functionality would exist in its own Actor class, but due to an
// issue with dfinity's current implementation, we can't communicate between
// actors unless all the calls are update (non-query) calls, which would cause
// a few-second delay when making any request. So instead, we shove all the
// "database" functionality right inside the "serve" actor. See
// https://forum.dfinity.org/t/cant-call-an-imported-actors-query-functions

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Map "mo:base/HashMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Types "types";
import Nft "../nft_db/nft_db";

module {
  public type Platform = Types.Platform;
  public type Source = Types.Source;
  public type Media = Types.Media;
  public type Feed = Types.Feed;
  public type PutFeedResult = Types.PutFeedResult;
  public type PutMediaResult = Types.PutMediaResult;
  public type StableCredits = Types.StableCredits;
  public type MediaSearchResult = Types.MediaSearchResult;
  public type CreditsError = Types.CreditsError;

  // After creating an instance of this class, call addCustodian on it to add
  // the identity that can manage the entire class. Usually this should be the
  // results of `dfx identity get-principal` so the class can be managed from
  // the command line.
  public class Credits(init: StableCredits) {
    let feeds: Map.HashMap<Text, Feed> = Map.fromIter<Text, Feed>(init.feedEntries.vals(), 1, Text.equal, Text.hash);
    var custodians = List.fromArray<Principal>(init.custodianEntries);

    public func asStable() : StableCredits = {
      feedEntries = Iter.toArray(feeds.entries());
      custodianEntries = List.toArray(custodians);
    };

    // Feeds
    public func putFeed(caller: Principal, key: Text, feed : Feed) : PutFeedResult {
      let isCustodian = List.some(custodians, func (custodian : Principal) : Bool { custodian == caller });
      switch(feeds.get(key)) {
        case (? existingFeed) {
          if (existingFeed.owner != caller) {
            // The feed already exists and is owned by a user other than the
            // caller. The only time we allow modifications to such feeds is
            // when the caller is the custodian, as long as they're not trying
            // to change the owner of the feed. This is necessary so the cloner
            // can modify feeds (e.g. to add media).
            if (not isCustodian or feed.owner != existingFeed.owner) {
              return #err(#KeyExists);
            };
          };
          feeds.put(key, feed);
          return #ok(#Updated);
        };
        case (null) {
          if (feed.owner != caller and not isCustodian) {
            // New feeds must be owned by the caller, unless the owner is a
            // custodian, who is allowed to create feeds owned by anyone (this
            // is so that the cloner works, which needs to be able to create
            // feeds for any user)
            return #err(#Unauthorized);
          };
          feeds.put(key, feed);
          return #ok(#Created);
        };
      };
    };

    public func deleteFeed(key: Text){
      feeds.delete(key);
    };

    public func getAllFeeds() : [(Text, Feed)] {
      Iter.toArray(feeds.entries());
    };

    public func getAllFeedKeys() : [Text] {
      Array.map(getAllFeeds(), func((key: Text, feed: Feed)) : Text { 
        key
      });
    };

    public func getFeed(key: Text) : ?Feed {
      feeds.get(key);
    };

    public func getMedia(feedKey: Text, episodeGuid: Text) : Types.MediaSearchResult {
      let feed = getFeed(feedKey);

      switch (feed) {
        case (null) #err(#FeedNotFound);
        case (?feed) {
          let media = Array.find(feed.mediaList, func (media: Media) : Bool { media.uri == episodeGuid }); // Assume or now that the media uri is the guid
          switch (media) {
            case (null) #err(#MediaNotFound);
            case (?media) {
              return #ok(media);
            }
          }
        };
      };
    };

    // Adds new Media to the specified feed. If media's episodeGuid (assumed to
    // be media.uri) matches that of a Media already in the feed, replaces that
    // Media instead of adding a new Media. This will fail silently (will
    // unintentially overwrite the previous Media) if trying to add two Media
    // with the same uri to the feed, for example for a re-release of an old
    // episode. 
    // todo: generate a unique episodeGuid for each episode.
    public func putMedia(feedKey: Text, media: Media) : PutMediaResult {
      //todo: check msg caller for feed ownership
      let feed = getFeed(feedKey);
      switch (feed) {
        case (null) return #err(#FeedNotFound);
        case (? feed) {
          // Temporarily convert to a Buffer to perform the modification/addition
          let newMediaListBuffer = Buffer.Buffer<Media>(feed.mediaList.size());
          var didReplace = false;
          Iter.iterate(Iter.fromArray(feed.mediaList), func(m: Media, _index: Nat) {
            // switch(episodeGuid) { case (null) { newMediaListBuffer.add(m);
            //   };
            //   case (?episodeGuid) {
            if (media.uri == m.uri) { // Assume episodeGuid is media.uri. 
              newMediaListBuffer.add(media);
              didReplace := true;
            } else {
              newMediaListBuffer.add(m);
            }
            //   }
            // }
          });
          if (not didReplace) {
            // if (episodeGuid != null) {
            //   // If an episodeGuid was specified, error if no media to replace
            //   return #err(#MediaNotFound); // No longer an error. This is expected when adding new Media.
            // };
            newMediaListBuffer.add(media);
          };

          let newFeed: Feed = {
            title = feed.title;
            subtitle = feed.subtitle;
            description = feed.description;
            link = feed.link;
            author = feed.author;
            email = feed.email;
            imageUrl = feed.imageUrl;
            owner = feed.owner;
            mediaList = newMediaListBuffer.toArray();
          };
          let _ = feeds.replace(feedKey, newFeed);
          return #ok(if didReplace { #Updated } else { #Created });
        };
      };
    };
    
    public func setNftTokenId(feedKey: Text, episodeGuid: Text, tokenId: Nft.TokenId) : Types.PutMediaResult {
      let mediaResult = getMedia(feedKey, episodeGuid);
      switch (mediaResult) {
        case (#err(err)) {
          return #err(err);
        };
        case (#ok(media)) {
          let newMedia: Media = {
            title = media.title;
            description = media.description;
            source = media.source;
            durationInMicroseconds = media.durationInMicroseconds;
            uri = media.uri;
            etag = media.etag;
            lengthInBytes = media.lengthInBytes;

            nftTokenId = Option.make(tokenId);
          };

          return putMedia(feedKey, newMedia);
        };
      };
    };

    public func getFeedSummary(key: Text) : (Text, Text) {
      let feed: ?Feed = getFeed(key);

      switch (feed) {
        case (?feed) {
          (feed.title, "items: " # Nat.toText(feed.mediaList.size()));
        };
        case (null) ("Unrecognized feed: " # key, "");
      };
    };

    public func getAllFeedSummaries() : async [(Text, Text)] {
      let keys: [Text] = getAllFeedKeys();
      var buffer = Buffer.Buffer<(Text, Text)>(keys.size()); 
      for (key in keys.vals()) {
        let summary = getFeedSummary(key); 
        buffer.add(summary);
      };
      buffer.toArray();
      // Not sure why this doesn't work instead of the above:
      // Array.map(keys, func(key: Text) : (Text, Text)
      //     {getFeedSummary(key);
      // });
    };

    public func getFeedMediaDetails(key: Text) : (Text, [(Text, Text)]) {
      let feed: ?Feed = getFeed(key);

      switch (feed) {
        case (?feed) {
          var buffer = Buffer.Buffer<(Text, Text)>(feed.mediaList.size()); 
          for (media in feed.mediaList.vals()) {
            let details = (media.source.releaseDate, media.title); 
            buffer.add(details);
          };
          let mediaDetails = buffer.toArray();
          // Not sure why this doesn't work instead of the above:
          // let mediaDetails = Array.map(feed.mediaList, func(media: Media) : (Text, Text) {
          //     (media.releaseDate, media.title);
          // });
          (feed.title, mediaDetails);
        };
        case (null) ("Unrecognized feed: " # key, []);
      };
    };

    public func getAllFeedMediaDetails() : async [(Text, [(Text, Text)])] {
      let keys: [Text] = getAllFeedKeys();
      var buffer = Buffer.Buffer<(Text, [(Text, Text)])>(keys.size()); 
      for (key in keys.vals()) {
        let details = getFeedMediaDetails(key); 
        buffer.add(details);
      };
      buffer.toArray();
      // Not sure why this doesn't work instead of the above:
      // Array.map(keys, func(key: Text) : (Text, Text)
      //     {getFeedSummary(key);
      // });
    };

    public func getSampleFeed() : Feed {
      {
        title = "Sample Feed";
        subtitle = "Just a sample";
        description = "A sample feed hosted on the Internet Computer";
        link = "http://example.com";
        author = "Mike Miller";
        email = "mike@videate.org";
        imageUrl = "https://www.learningcontainer.com/wp-content/uploads/2019/10/Learning-container.png";
        owner = Principal.fromText("7ox2k-63z7o-qnmk7-btjy4-ntcgm-g4vkx-3v2jy-xh2sh-bo3pb-i46mj-kqe");
        mediaList = [
          {
            uri = "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4";
            etag = "a1b2c3";
            lengthInBytes = 12345;
            title = "Test video";
            description = "Test";
            durationInMicroseconds = 987654321;
            nftTokenId = null;
            source = {
              platform = {
                uri = "http://videate.org/";
                id = "videate";
              };
              uri = "https://www.learningcontainer.com/mp4-sample-video-files-download/#Sample_MP4_File";
              id = "test";
              releaseDate = "1970-01-01T00:00:00.000Z";
            };
          }
        ];
      };
    };

    public func isInitialized(): Bool {    
      return List.size(custodians) > 0
    };

    public func addCustodian(caller: Principal, newCustodian: Principal) : Result.Result<(), CreditsError> {
      // Once we've been initialized, only current custodians can add a new
      // custodian. Note that we allow anyone (usually the deployer since the
      // initalize call should be done immediately after deploying or else there
      // won't be a custodian and many functions in this class won't work) to
      // specify the first custodian, usually the identity for their dfx (the
      // caller of serveActor.initialize()) so they can manage this class via the
      // console.
      if (isInitialized() and not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })) {
        return #err(#Unauthorized);
      };

      // Add the new custodian if it's not already in the list
      if (not List.some(custodians, func (custodian : Principal) : Bool { custodian == newCustodian })) {
        custodians := List.push(newCustodian, custodians);
      };

      return #ok();
    };
  };
};
