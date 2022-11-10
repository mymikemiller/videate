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
import Utils "../utils";
import Nft "../nft_db/nft_db";

module {
  public type Platform = Types.Platform;
  public type Source = Types.Source;
  public type MediaID = Types.MediaID;
  public type Media = Types.Media;
  public type MediaData = Types.MediaData;
  public type EpisodeID = Types.EpisodeID;
  public type Episode = Types.Episode;
  public type EpisodeData = Types.EpisodeData;
  public type FeedKey = Types.FeedKey;
  public type Feed = Types.Feed;
  public type PutResult = Types.PutResult;
  public type StableCredits = Types.StableCredits;
  public type EpisodeSearchResult = Types.EpisodeSearchResult;
  public type CreditsError = Types.CreditsError;

  // After creating an instance of this class, call addCustodian on it to add
  // the identity that can manage the entire class. Usually this should be the
  // results of `dfx identity get-principal` so the class can be managed from
  // the command line.
  public class Credits(init : StableCredits) {
    let feeds : Map.HashMap<FeedKey, Feed> = Map.fromIter<FeedKey, Feed>(
      init.feedEntries.vals(),
      1,
      Text.equal,
      Text.hash,
    );

    let media : Buffer.Buffer<Media> = Utils.bufferFromArray<Media>(init.mediaEntries);

    // Turn the stable array of all Episodes into a usable map from FeedKey to
    // a Buffer of Episodes in that Feed. Once an Episode is added to this map,
    // it stays there even if its EpisodeID is removed from the feed's
    // episodeIds list, thus removing the Episode from the feed.
    let episodes : Map.HashMap<FeedKey, Buffer.Buffer<Episode>> = Array.foldLeft<Episode, Map.HashMap<FeedKey, Buffer.Buffer<Episode>>>(
      init.episodeEntries,
      Map.fromIter<FeedKey, Buffer.Buffer<Episode>>(
        Iter.fromArray([]),
        1,
        Text.equal,
        Text.hash,
      ),
      func(map : Map.HashMap<FeedKey, Buffer.Buffer<Episode>>, episode : Episode) {
        switch (map.get(episode.feedKey)) {
          case (null) {
            // Initialize with a Buffer containing only the current Episode
            let newBuffer = Utils.bufferFromArray<Episode>(Array.make<Episode>(episode));
            map.put(episode.feedKey, newBuffer);
          };
          case (?episodeBuffer) {
            // Add the current Episode to the existing buffer
            episodeBuffer.add(episode);
          };
        };
        map;
      },
    );

    var custodians = List.fromArray<Principal>(init.custodianEntries);

    public func asStable() : StableCredits = {
      mediaEntries = media.toArray();

      // Flatten the values from the map of FeedKey->Buffer<Episode> into an
      // array of all Episodes on the platform
      episodeEntries = Array.flatten<Episode>(
        Iter.toArray(
          Iter.map<Buffer.Buffer<Episode>, [Episode]>(
            episodes.vals(),
            func(buffer : Buffer.Buffer<Episode>) : [Episode] {
              buffer.toArray();
            },
          ),
        ),
      );

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

    public func getAllEpisodes(feedKey : Text) : [Episode] {
      let buffer = episodes.get(feedKey);
      switch (buffer) {
        case null [];
        case (?buffer) {
          buffer.toArray();
        };
      };
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

    public func getMedia(id : MediaID) : ?Media {
      media.getOpt(id);
    };

    public func getEpisode(key : FeedKey, id : EpisodeID) : ?Episode {
      let episodeBuffer = episodes.get(key);
      switch (episodeBuffer) {
        case (null) {
          // Either the Feed does not exist, or it contains no Episodes yet.
          // The caller can use getFeed() to determine which case resulted in
          // null being returned.
          null;
        };
        case (?episodeBuffer) {
          if (id >= episodeBuffer.size()) {
            // The Episode buffer exists (thus likely the Feed exists), but
            // there is no Episode with the given id
            return null;
          };
          return Option.make(episodeBuffer.get(id));
        };
      };
    };

    // Null return value means the feed wasn't found, empty array means the
    // feed was found but does not contain any Episodes.
    public func getEpisodes(key : FeedKey) : ?[Episode] {
      // We can't just use episodes.get(key) because the feed's list of
      // EpisodeIDs into that array is the source of truth for what Episodes
      // are actually in the Feed.
      let episodeIds : [EpisodeID] = switch (getFeed(key)) {
        case null return null; // Feed not found, return null
        case (?feed) feed.episodeIds;
      };

      if (episodeIds.size() == 0) {
        // Not an error case (just no episodes yet). We special-case this here
        // since episodes.get(key) will likely return null below
        return Option.make([]);
      };

      switch (episodes.get(key)) {
        case null {
          // If a feed has EpisodeIDs in its episodeIds list, there shold
          // be Episodes in its Episodes buffer
          Debug.trap("No episodes buffer found for feed " # key);
        };
        case (?possibleEpisodes) {
          let episodeArray = Array.tabulate<Episode>(
            episodeIds.size(),
            func(index : Nat) : Episode {
              let episodeId : EpisodeID = episodeIds[index];
              possibleEpisodes.get(episodeId);
            },
          );
          Option.make(episodeArray);
        };
      };
    };

    public func addMedia(mediaData : MediaData) : Result.Result<Media, CreditsError> {
      // Create the Media now that we know what the MediaID will be
      let newMedia : Media = {
        // MediaIDs increase linearly from 0, so we know the next available
        // MediaID matches the size of the buffer before this one is added
        id = media.size();
        source = mediaData.source;
        durationInMicroseconds = mediaData.durationInMicroseconds;
        uri = mediaData.uri;
        etag = mediaData.etag;
        lengthInBytes = mediaData.lengthInBytes;
      };

      // Add the Media
      media.add(newMedia);
      return #ok(newMedia);
    };

    public func updateMedia(newMedia : Media) : Result.Result<(), CreditsError> {
      // Verify that a Media exists to replace
      if (newMedia.id >= media.size()) {
        return #err(#Other("No Media with id " # Nat.toText(newMedia.id) # " found to replace"));
      };
      // Replace with the new Media
      media.put(newMedia.id, newMedia);
      return #ok();
    };

    public func addEpisode(episodeData : EpisodeData) : Result.Result<Episode, CreditsError> {
      // First make sure a Feed exists with the given FeedKey
      let feed : Feed = switch (getFeed(episodeData.feedKey)) {
        case (null) {
          return #err(#FeedNotFound);
        };
        case (?feed) {
          feed;
        };
      };

      //todo: check msg caller for feed ownership

      let episodeBuffer = switch (episodes.get(episodeData.feedKey)) {
        case (null) {
          // This is the feed's first episode, so create the buffer
          Utils.bufferFromArray<Episode>([]);
        };
        case (?episodeBuffer) {
          episodeBuffer;
        };
      };

      //todo: use object combination to simplify this. See
      // https://internetcomputer.org/docs/current/developer-docs/build/cdks/motoko-dfinity/language-manual#object-combinationextension
      // and https://github.com/dfinity/motoko/pull/3084
      let episode : Episode = {
        title = episodeData.title;
        description = episodeData.description;
        mediaId = episodeData.mediaId;
        feedKey = episodeData.feedKey;
        id = episodeBuffer.size(); // EpisodeIDs are 0-based and always match the index into episodeBuffer
        nftTokenId = null;
      };

      // Add the Episode
      episodeBuffer.add(episode);
      let _ = episodes.replace(feed.key, episodeBuffer);

      // Get the new list of episodeIds for the feed
      let buffer = Utils.bufferFromArray<EpisodeID>(feed.episodeIds);
      buffer.add(episode.id);
      let newEpisodeIds : [EpisodeID] = buffer.toArray();

      // The following should work to modify the feed's episode list, but gives "unexpected token 'and'" or "unexpected token 'with'"
      // let updatedFeed : Feed = {
      //   episode.feed with episodes = episodesBuffer.toArray();
      // }

      // Why doesn't this work? See https://internetcomputer.org/docs/current/developer-docs/build/cdks/motoko-dfinity/language-manual#object-combinationextension and https://github.com/dfinity/motoko/pull/3084
      // let a = { x = 1 };
      // let b = { y = 2 };
      // let c = { a and b with x = 3 };

      let updatedFeed : Feed = {
        key = feed.key;
        title = feed.title;
        subtitle = feed.subtitle;
        description = feed.description;
        link = feed.link;
        author = feed.author;
        email = feed.email;
        imageUrl = feed.imageUrl;
        owner = feed.owner;
        episodeIds = newEpisodeIds;
      };
      let _ = feeds.replace(feed.key, updatedFeed);
      return #ok(episode);
    };

    // Overwrite the Episode at episode.id in episode.feed with the given Episode
    public func updateEpisode(episode : Episode) : Result.Result<(), CreditsError> {
      // First make sure a Feed exists with the given FeedKey
      let feedKey : FeedKey = episode.feedKey;
      let feed : Feed = switch (getFeed(feedKey)) {
        case (null) {
          return #err(#FeedNotFound);
        };
        case (?feed) {
          feed;
        };
      };

      //todo: check msg caller for feed ownership

      let episodeBuffer = switch (episodes.get(feedKey)) {
        case (null) {
          // Since we're updating not adding, we expect to find the episode
          // buffer in the episodes array
          return #err(#EpisodeNotFound);
        };
        case (?episodeBuffer) {
          episodeBuffer;
        };
      };

      // Make sure the provided Episode is in the Episode buffer for the feed
      if (episode.id >= episodeBuffer.size()) {
        return #err(#EpisodeNotFound);
      };

      // Modify the Episode
      episodeBuffer.put(episode.id, episode);

      return #ok();
    };

    public func setNftTokenId(
      episode : Episode,
      tokenId : Nft.TokenId,
    ) : Result.Result<(), CreditsError> {

      // This should work, but gives errors about unexpected 'with' and 'and' tokens
      // let episodeWithNftTokenId : Episode = {
      //   episode with nftTokenId = Option.make(tokenId);
      // };

      let episodeWithNftTokenId : Episode = {
        title = episode.title;
        description = episode.description;
        mediaId = episode.mediaId;
        feedKey = episode.feedKey;
        id = episode.id;

        nftTokenId = Option.make(tokenId);
      };

      return updateEpisode(episodeWithNftTokenId);
    };

    public func getFeedSummary(key : FeedKey) : (Text, Text) {
      let feed : ?Feed = getFeed(key);

      switch (feed) {
        case (?feed) {
          (feed.title, "episodes: " # Nat.toText(feed.episodeIds.size()));
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

    public func getFeedEpisodeDetails(key : FeedKey) : (Text, [(Text, Text)]) {
      switch (getFeed(key)) {
        case (null)("Unrecognized feed: " # key, []);
        case (?feed) {
          (
            feed.title,
            Array.map<EpisodeID, (Text, Text)>(
              feed.episodeIds,
              func(episodeId : EpisodeID) : (Text, Text) {
                switch (getEpisode(key, episodeId)) {
                  case (null)("Episode " # Nat.toText(episodeId) # " not found in " # key # " feed", "");
                  case (?episode) {
                    switch (getMedia(episode.mediaId)) {
                      case (null)("Unrecognized mediaId " # debug_show (episode.mediaId), "");
                      case (?media) {
                        (media.source.releaseDate, episode.title);
                      };
                    };
                  };
                };
              },
            ),
          );
        };
      };
    };

    public func getAllFeedEpisodeDetails() : async [(Text, [(Text, Text)])] {
      let keys : [FeedKey] = getAllFeedKeys();
      Array.map<FeedKey, (Text, [(Text, Text)])>(
        keys,
        func(key : FeedKey) : (Text, [(Text, Text)]) {
          getFeedEpisodeDetails(key);
        },
      );
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
