
// This is the Motoko version of
// [nomeata](https://forum.dfinity.org/u/nomeata)'s Rust
// [example](https://github.com/nomeata/ic-telegram-bot) utilizing his [proxy
// solution](https://github.com/nomeata/ic-http-lambda/) for being able to
// return xml and media from Internet Computer canisters. See the [forum
// discussion](https://forum.dfinity.org/t/can-a-canister-return-generated-xml/1636/7)
//
// Specifically, this file is modeled after nomeata's Rust example here:
// https://github.com/nomeata/ic-telegram-bot/blob/main/telegram/src/lib.rs
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Word32 "mo:base/Word32";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Credits "canister:credits";
import Xml "xml";
import Types "types";
import Utils "utils";
import Rss "rss";

actor Serve {
    type Request = Types.Request;
    type Response = Types.Response;
    type Feed = Credits.Feed;
    type Document = Xml.Document;

    let sampleFeed = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> <rss xmlns:itunes=\"http://www.itunes.com/dtds/podcast-1.0.dtd\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\" xmlns:atom=\"http://www.w3.org/2005/Atom\" version=\"2.0\"> <channel> <atom:link href=\"http://mikem-18bd0e1e.localhost.run/\" rel=\"self\" type=\"application/rss+xml\"></atom:link> <title>Sample Feed</title> <link>http://example.com</link> <language>en-us</language> <itunes:subtitle>Just a sample</itunes:subtitle> <itunes:author>Mike Miller</itunes:author> <itunes:summary>A sample feed hosted on the Internet Computer</itunes:summary> <description>A sample feed hosted on the Internet Computer</description> <itunes:owner> <itunes:name>Mike Miller</itunes:name> <itunes:email>mike@videate.org</itunes:email> </itunes:owner> <itunes:explicit>no</itunes:explicit> <itunes:image href=\"https://brianchristner.io/content/images/2016/01/Success-loading.jpg\"></itunes:image> <itunes:category text=\"Arts\"></itunes:category> <item> <title>test</title> <itunes:summary>test</itunes:summary> <description>test</description> <link>http://example.com/podcast-1</link> <enclosure url=\"https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4\" type=\"video/mpeg\" length=\"1024\"></enclosure> <pubDate>21 Dec 2016 16:01:07 +0000</pubDate> <itunes:author>Mike Miller</itunes:author> <itunes:duration>00:32:16</itunes:duration> <itunes:explicit>no</itunes:explicit> <guid></guid> </item> </channel> </rss>";

    // We must always upgrade to a non-query call because we're currently not
    // able to call into the Credit actor's functions from inside a query
    // function (see
    // https://forum.dfinity.org/t/cant-call-an-imported-actors-query-functions/1732).
    // Plus we need to make modifications anyway to record that the media/feed
    // was downloaded by the contributor.
    public query func http_query(request: Request) : async Response {
        // todo: this should be able to use Utils.generateUpgradeResponse(),
        // but I end up with "type error, send capability required, but not
        // available (need an enclosing async expression or function body)"
        // when trying that. See
        // https://forum.dfinity.org/t/cant-call-an-imported-actors-query-functions/1732.
        // I can't just change this to a non-query function as suggested on
        // that forum, though, because this must conform to ic-http-bridge's
        // expectations.

        // Short-circuit simple requests
        if (request.uri == "/favicon.ico") {
            return {
                status = Nat16.fromNat(200);
                headers = Utils.toNat8ArrayTupleArray([("content-type", "image/x-icon")]);
                body = Utils.toNat8Array(""); // Send empty icon
                upgrade = false;
            };
        } else if (request.uri == "/pr0n") {
            // https://www.textfixer.com/tools/remove-line-breaks.php
            // https://onlinestringtools.com/escape-string
            return {
                status = Nat16.fromNat(200);
                headers = Utils.toNat8ArrayTupleArray([("content-type", "text/xml")]);
                body = Utils.toNat8Array("<?xml version=\"1.0\" encoding=\"UTF-8\"?> <rss xmlns:itunes=\"http://www.itunes.com/dtds/podcast-1.0.dtd\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\" xmlns:atom=\"http://www.w3.org/2005/Atom\" version=\"2.0\"> <channel> <atom:link href=\"http://mikem-18bd0e1e.localhost.run/test\" rel=\"self\" type=\"application/rss+xml\"></atom:link> <title>Sample Feed</title> <link>http://example.com</link> <language>en-us</language> <itunes:subtitle>Just a sample</itunes:subtitle> <itunes:author>Mike Miller</itunes:author> <itunes:summary>A sample feed hosted on the Internet Computer</itunes:summary> <description>A sample feed hosted on the Internet Computer</description> <itunes:owner> <itunes:name>Mike Miller</itunes:name> <itunes:email>mike@videate.org</itunes:email> </itunes:owner> <itunes:explicit>no</itunes:explicit> <itunes:image href=\"https://brianchristner.io/content/images/2016/01/Success-loading.jpg\"></itunes:image> <itunes:category text=\"Arts\"></itunes:category> <item> <title>test</title> <itunes:summary>test</itunes:summary> <description>test</description> <link>http://example.com/podcast-1</link> <enclosure url=\"http://videate.org/local/test.mp4\" type=\"video/mpeg\" length=\"1024\"></enclosure> <pubDate>21 Dec 2016 16:01:07 +0000</pubDate> <itunes:author>Mike Miller</itunes:author> <itunes:duration>00:32:16</itunes:duration> <itunes:explicit>no</itunes:explicit> <guid></guid> </item> </channel> </rss>");
                upgrade = false;
            };
        } else if (request.uri == "/fast") {
            // https://www.textfixer.com/tools/remove-line-breaks.php
            // https://onlinestringtools.com/escape-string
            return {
                status = Nat16.fromNat(200);
                headers = Utils.toNat8ArrayTupleArray([("content-type", "text/xml")]);
                body = Utils.toNat8Array(sampleFeed);
                upgrade = false;
            };
        };
        
        // Translate the inputs to the expected types
        var statusNat16 = Nat16.fromNat(200);
        var bodyNat8Array = Utils.toNat8Array("Upgrading to non-query call");
        var headersNat8 = Utils.toNat8ArrayTupleArray([("content-type", "text/plain")]);

        var response: Response = {
            status = statusNat16;
            headers = headersNat8;
            body = bodyNat8Array;
            upgrade = true;
        };
        Debug.print("upgrading");
        return response;
    };
    
    public func http_update(request: Request) : async Response {
        Debug.print("http_update");
        var xml = "";
        if (request.uri == "/slow") {
            Debug.print("using hard-coded \"slow\" feed");
            xml := sampleFeed;
        } else {
            let uriIter = Text.split(request.uri, #char '/');
            let requestParts = Iter.toArray(uriIter);
            let feedName = requestParts[1];
            Debug.print("generating \"" # feedName # "\" feed");
            xml := await getFeedXml(feedName);
        };
        
        var response = await Utils.generateFeedResponse(xml);
        Debug.print("Returning feed response");
        return response;
    };

    public func getFeedXml(key: Text) : async Text {
        let feed: ?Feed = await Credits.getFeed(key);

        switch(feed) {
            case null "Unrecognized feed: " # key;
            case (?feed) {
                let doc: Document = await Rss.format(feed);
                Xml.stringifyDocument(doc);
            };
        };
    };
};
