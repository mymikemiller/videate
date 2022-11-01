// Ideally this functionality would exist in its own Actor class, but due to an
// issue with dfinity's current implementation, we can't communicate between
// actors unless all the calls are update (non-query) calls, which would cause
// a few-second delay when making any request. So instead, we shove all the
// "database" functionality right inside the "serve" actor. See
// https://forum.dfinity.org/t/cant-call-an-imported-actors-query-functions

import Array "mo:base/Array";
import Map "mo:base/HashMap";
import Buffer "mo:base/Buffer";
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
  public type Episode = Types.Episode;
  public type EpisodeData = Types.EpisodeData;
  public type FeedKey = Types.FeedKey;
  public type Feed = Types.Feed;
  public type PutResult = Types.PutResult;
  public type PutEpisodeResult = Types.PutEpisodeResult;
  public type StableCredits = Types.StableCredits;
  public type EpisodeSearchResult = Types.EpisodeSearchResult;
  public type CreditsError = Types.CreditsError;

  // After creating an instance of this class, call addCustodian on it to add
  // the identity that can manage the entire class. Usually this should be the
  // results of `dfx identity get-principal` so the class can be managed from
  // the command line.
  public class Credits(init : StableCredits) {
    let feeds : Map.HashMap<Text, Feed> = Map.fromIter<Text, Feed>(
      init.feedEntries.vals(),
      1,
      Text.equal,
      Text.hash,
    );
    var custodians = List.fromArray<Principal>(init.custodianEntries);

    public func asStable() : StableCredits = {
      feedEntries = Iter.toArray(feeds.entries());
      custodianEntries = List.toArray(custodians);
    };

    // Feeds
    public func putFeed(caller : Principal, feed : Feed) : PutResult {
      let isCustodian = List.some(
        custodians,
        func(custodian : Principal) : Bool { custodian == caller },
      );
      switch (feeds.get(feed.key)) {
        case (?existingFeed) {
          if (existingFeed.owner != caller) {
            // The feed already exists and is owned by a user other than the
            // caller. The only time we allow modifications to such feeds is
            // when the caller is the custodian, as long as they're not trying
            // to change the owner of the feed. This is necessary so the cloner
            // can modify feeds (e.g. to add episodes).
            if (not isCustodian or feed.owner != existingFeed.owner) {
              return #err(#KeyExists);
            };
          };
          feeds.put(feed.key, feed);
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
          feeds.put(feed.key, feed);
          return #ok(#Added);
        };
      };
    };

    public func deleteFeed(key : Text) {
      feeds.delete(key);
    };

    public func getAllFeeds() : [(Text, Feed)] {
      Iter.toArray(feeds.entries());
    };

    public func getAllFeedKeys() : [Text] {
      Array.map(
        getAllFeeds(),
        func((key : Text, feed : Feed)) : Text {
          key;
        },
      );
    };

    public func getFeed(key : FeedKey) : ?Feed {
      feeds.get(key);
    };

    public func getEpisode(key : FeedKey, number : Nat) : Types.EpisodeSearchResult {
      let feed = getFeed(key);

      switch (feed) {
        case (null) #err(#FeedNotFound);
        case (?feed) {
          if (number > feed.episodes.size()) {
            return #err(#EpisodeNotFound);
          };
          // number is 1-based
          let episode = feed.episodes[number - 1];
          return #ok(episode);
        };
      };
    };

    public func addEpisode(feed : Feed, episodeData : EpisodeData) : PutEpisodeResult {
      putEpisode(#Add { feed; episodeData });
    };

    public func updateEpisode(episode : Episode) : PutEpisodeResult {
      putEpisode(#Update { episode });
    };

    // Adds a new Episode with the given data to the given feed and returns the
    // newly created Episode, or updates an existing Episode
    func putEpisode(
      instructions : {
        #Add : { feed : Feed; episodeData : EpisodeData };
        #Update : { episode : Episode };
      },
    ) : PutEpisodeResult {
      //todo: check msg caller for feed ownership
      var updating = true;
      let episode : Episode = switch instructions {
        case (#Update(data : { episode : Episode })) {
          // todo: do we need this check? It fails because episode doesn't exist in data.episode.feed.episodes, which is empty
          // if (data.episode.number > data.episode.feed.episodes.size()) {
          //   Debug.print("data.episode.number > data.episode.feed.episodes.size()");
          //   Debug.print(debug_show (data.episode.number) # " > " # debug_show (data.episode.feed.episodes.size()));
          //   // No Episode at the specified index (index = number-1) to update
          //   return #err(#EpisodeNotFound);
          // };
          data.episode;
        };
        case (#Add(data : { feed : Feed; episodeData : EpisodeData })) {
          updating := false;
          let episodeData = data.episodeData;
          let e : Episode = {
            title = episodeData.title;
            description = episodeData.description;
            media = episodeData.media;
            feed = data.feed;
            // episodeData with feed = data.feed; number is 1-based
            number = data.feed.episodes.size() + 1;
            nftTokenId = null;
          };

          e;
        };
      };

      // Temporarily convert to a Buffer to perform the modification/addition
      let episodesBuffer = Buffer.Buffer<Episode>(episode.feed.episodes.size() + (if (updating) 0 else 1));
      for (i in episode.feed.episodes.keys()) {
        let existingEpisode = episode.feed.episodes[i];
        if ((episode.number - 1) : Nat == i) {
          // Update (replace) Episode
          episodesBuffer.add(episode);
        } else {
          // Sanity check for existing episodes
          if ((existingEpisode.number - 1) : Nat != i) {
            // This should never happen as long as Episodes are always
            // added/updated to/in Feeds via this function, and are never
            // removed from the middle of the list.
            return #err(#Other("Encountered out-of-order episode number " # debug_show (episode.number) # " at index " # debug_show (i) # " in \"" # episode.feed.key # "\" feed. An Episode's number should always be equal to 1 + the index into Episode's Feed's Episode list."));
          };
          // Retain existing Episodes
          episodesBuffer.add(existingEpisode);
        };
      };

      if (not updating) {
        // We're intending to add a new Episode, so add the it to the end
        episodesBuffer.add(episode);
      };

      // The following should work to modify the feed's episode list, but gives "unexpected token 'and'" or "unexpected token 'with'"
      // let updatedFeed : Feed = {
      //   episode.feed with episodes = episodesBuffer.toArray();
      // }

      // Why doesn't this work? See https://internetcomputer.org/docs/current/developer-docs/build/cdks/motoko-dfinity/language-manual#object-combinationextension and https://github.com/dfinity/motoko/pull/3084
      // let a = { x = 1 };
      // let b = { y = 2 };
      // let c = { a and b with x = 3 };

      let updatedFeed : Feed = {
        key = episode.feed.key;
        title = episode.feed.title;
        subtitle = episode.feed.subtitle;
        description = episode.feed.description;
        link = episode.feed.link;
        author = episode.feed.author;
        email = episode.feed.email;
        imageUrl = episode.feed.imageUrl;
        owner = episode.feed.owner;
        episodes = episodesBuffer.toArray();
      };
      let _ = feeds.replace(episode.feed.key, updatedFeed);
      return #ok(if (updating) { #Updated } else { #Added { episode } });
    };

    public func setNftTokenId(
      episode : Episode,
      tokenId : Nft.TokenId,
    ) : PutEpisodeResult {

      // This should work, but gives errors about unexpected 'with' and 'and' tokens
      // let episodeWithNftTokenId : Episode = {
      //   episode with nftTokenId = Option.make(tokenId);
      // };

      let episodeWithNftTokenId : Episode = {
        title = episode.title;
        description = episode.description;
        media = episode.media;
        feed = episode.feed;
        number = episode.number;

        nftTokenId = Option.make(tokenId);
      };

      return updateEpisode(episodeWithNftTokenId);
    };

    public func getFeedSummary(key : Text) : (Text, Text) {
      let feed : ?Feed = getFeed(key);

      switch (feed) {
        case (?feed) {
          (feed.title, "episodes: " # Nat.toText(feed.episodes.size()));
        };
        case (null)("Unrecognized feed: " # key, "");
      };
    };

    public func getAllFeedSummaries() : async [(Text, Text)] {
      let keys : [Text] = getAllFeedKeys();
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

    public func getFeedEpisodeDetails(key : Text) : (Text, [(Text, Text)]) {
      let feed : ?Feed = getFeed(key);

      switch (feed) {
        case (?feed) {
          var buffer = Buffer.Buffer<(Text, Text)>(feed.episodes.size());
          for (episode in feed.episodes.vals()) {
            let details = (episode.media.source.releaseDate, episode.title);
            buffer.add(details);
          };
          let details = buffer.toArray();
          // Not sure why this doesn't work instead of the above:
          // let details = Array.map(feed.mediaList, func(media: Media) : (Text, Text) {
          //     (media.releaseDate, media.title);
          // });
          (feed.title, details);
        };
        case (null)("Unrecognized feed: " # key, []);
      };
    };

    public func getAllFeedEpisodeDetails() : async [(Text, [(Text, Text)])] {
      let keys : [Text] = getAllFeedKeys();
      var buffer = Buffer.Buffer<(Text, [(Text, Text)])>(keys.size());
      for (key in keys.vals()) {
        let details = getFeedEpisodeDetails(key);
        buffer.add(details);
      };
      buffer.toArray();
      // Not sure why this doesn't work instead of the above:
      // Array.map(keys, func(key: Text) : (Text, Text)
      //     {getFeedSummary(key);
      // });
    };

    /*
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
        episodes = [
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
          },
        ];
      };
    };
    */

    public func isInitialized() : Bool {
      return List.size(custodians) > 0;
    };

    public func addCustodian(caller : Principal, newCustodian : Principal) : Result.Result<(), CreditsError> {
      // Once we've been initialized, only current custodians can add a new
      // custodian. Note that we allow anyone (usually the deployer since the
      // initalize call should be done immediately after deploying or else there
      // won't be a custodian and many functions in this class won't work) to
      // specify the first custodian, usually the identity for their dfx (the
      // caller of serveActor.initialize()) so they can manage this class via the
      // console.
      if (isInitialized() and not List.some(custodians, func(custodian : Principal) : Bool { custodian == caller })) {
        return #err(#Unauthorized);
      };

      // Add the new custodian if it's not already in the list
      if (not List.some(custodians, func(custodian : Principal) : Bool { custodian == newCustodian })) {
        custodians := List.push(newCustodian, custodians);
      };

      return #ok();
    };
  };
};
