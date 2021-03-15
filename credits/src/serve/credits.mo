// Ideally this functionality would exist in its own Actor class, but due to an
// issue with dfinity's current implementation, we can't communicate between
// actors unless all the calls are update (non-query) calls, which would cause
// a ~30-second delay when making any request. So instead, we shove all the
// "database" functionality right inside the "serve" actor.

import Buffer "mo:base/Buffer";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Map "mo:base/HashMap";
import Types "types";

module {

    public type Platform = Types.Platform;
    public type Source = Types.Source;
    public type Media = Types.Media;
    public type Feed = Types.Feed;
    type StableCredits = Types.StableCredits;

    public class Credits(init: StableCredits) {
        let feeds: Map.HashMap<Text, Feed> = Map.fromIter<Text, Feed>(init.feedEntries.vals(), 1, Text.equal, Text.hash);

        public func asStable() : StableCredits = {
            feedEntries = Iter.toArray(feeds.entries());
        };

        // var allMedia = Buffer.Buffer<Media>(10);

        // Media
        // public func addMedia(media : Media) : async Nat {
        //     allMedia.add(media);
        //     allMedia.size() - 1;
        // };

        // public func removeLastMedia() : async ?Media {
        //     allMedia.removeLast();
        // };

        // public query func getAllMedia() : async [Media] {
        //     allMedia.toArray();
        // };

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

        public func getFeed(key: Text) : ?Feed {
            feeds.get(key);
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
                        title = "Test video";
                        description = "Test";
                        source = {
                            platform = {
                                uri = "http://videate.org/";
                                id = "videate";
                            };
                            uri = "https://www.learningcontainer.com/mp4-sample-video-files-download/#Sample_MP4_File";
                            id = "test";
                        };
                        // contributors =;
                        // duration =;
                        uri = "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4";
                        // etag =;
                        // lengthInBytea =;
                    }
                ];
            };
        };
    }


    
}
