import Buffer "mo:base/Buffer";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Types "types";

actor Credits {
    type Platform = Types.Platform;
    type Source = Types.Source;
    type Media = Types.Media;
    type Feed = Types.Feed;

    // This pattern uses `preupgrade` and `postupgrade` to allow `feeds` to be
    // stable even though HashMap is not. See
    // https://sdk.dfinity.org/docs/language-guide/upgrades.html#_preupgrade_and_postupgrade_system_methods
    stable var feedEntries : [(Text, Feed)] = [];
    let feeds = HashMap.fromIter(feedEntries.vals(), 10, Text.equal, Text.hash);

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
    public func addFeed(key: Text, feed : Feed) : async Nat {
        feeds.put(key, feed);
        feeds.size() - 1;
    };

    public func deleteFeed(key: Text){
        feeds.delete(key);
    };

    public query func getAllFeeds() : async [(Text, Feed)] {
        Iter.toArray(feeds.entries());
    };

    public query func getFeed(key: Text) : async ?Feed {
        feeds.get(key);
    };


    system func preupgrade() {
        feedEntries := Iter.toArray(feeds.entries());
    };

    system func postupgrade() {
        feedEntries := [];
    };

    public query func getSampleFeed() : async Feed {
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
};
