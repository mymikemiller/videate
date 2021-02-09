import Buffer "mo:base/Buffer";
import List "mo:base/List";
import Types "types";

actor Credits {
    type Platform = Types.Platform;
    type Source = Types.Source;
    type Media = Types.Media;
    type Feed = Types.Feed;

    var allMedia = Buffer.Buffer<Media>(10);

    public func addMedia(media : Media) : async Nat {
        allMedia.add(media);
        allMedia.size() - 1;
    };

    public func removeLastMedia() : async ?Media {
        allMedia.removeLast();
    };

    public query func getAllMedia() : async [Media] {
        allMedia.toArray();
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
