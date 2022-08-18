// Ideally this functionality would exist in its own Actor class, but due to an
// issue with dfinity's current implementation, we can't communicate between
// actors unless all the calls are update (non-query) calls, which would cause
// a ~30-second delay when making any request. So instead, we shove all the
// "database" functionality right inside the "serve" actor. See
// https://forum.dfinity.org/t/cant-call-an-imported-actors-query-functions

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Map "mo:base/HashMap";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Types "types";
import Nft "../nft_db/nft_db";

module {
    public type Platform = Types.Platform;
    public type Source = Types.Source;
    public type Media = Types.Media;
    public type Feed = Types.Feed;
    public type StableCredits = Types.StableCredits;
    public type MediaSearchResult = Types.MediaSearchResult;
    public type SearchError = Types.SearchError;

    public class Credits(init: StableCredits) {
        let feeds: Map.HashMap<Text, Feed> = Map.fromIter<Text, Feed>(init.feedEntries.vals(), 1, Text.equal, Text.hash);

        public func asStable() : StableCredits = {
            feedEntries = Iter.toArray(feeds.entries());
        };

        // Feeds
        public func addFeed(key: Text, feed : Feed) : Nat {
            feeds.put(key, feed);
            feeds.size() - 1;
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
                case (null) #Err(#FeedNotFound);
                case (?feed) {
                    let media = Array.find(feed.mediaList, func (media: Media) : Bool { media.uri == episodeGuid }); // Assume or now that the media uri is the guid
                    switch (media) {
                        case (null) #Err(#MediaNotFound);
                        case (?media) {
                            return #Ok(media);
                        }
                    }
                };
            };
        };

        func updateMedia(feedKey: Text, episodeGuid: Text, newMedia: Media) : ?Media {
            let feed = getFeed(feedKey);
            switch (feed) {
                case (null) return null;
                case (? feed) {
                    let newFeed: Feed = {
                        title = feed.title;
                        subtitle = feed.subtitle;
                        description = feed.description;
                        link = feed.link;
                        author = feed.author;
                        email = feed.email;
                        imageUrl = feed.imageUrl;
                        mediaList = Array.map<Media, Media>(feed.mediaList, func (media) {
                            if (media.uri == episodeGuid) newMedia else media;
                        });
                    };
                    let _ = feeds.replace(feedKey, newFeed);
                    return Option.make(newMedia);
                };
            };
        };
        
        public func setNftTokenId(feedKey: Text, episodeGuid: Text, tokenId: Nft.TokenId) : Types.MediaSearchResult {
            let mediaResult = getMedia(feedKey, episodeGuid);
            switch (mediaResult) {
                case (#Ok(media)) {
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

                    let _ = updateMedia(feedKey, episodeGuid, newMedia);
                };
                case (#Err(err)) {
                    // Do nothing, just return the result which includes the
                    // error
                };
            };
            return mediaResult;
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
    }
}
