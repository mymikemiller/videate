import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import HashMap "mo:base/HashMap";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Credits "credits";
import Xml "xml";
import Types "types";
import Utils "utils";
import Rss "rss";

actor class Serve() = this {
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;
    type StableCredits = Types.StableCredits;
    type Feed = Credits.Feed;
    type Document = Xml.Document;
    type UriTransformer = Types.UriTransformer;
    type Media = Types.Media;

    let sampleFeed = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> <rss xmlns:itunes=\"http://www.itunes.com/dtds/podcast-1.0.dtd\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\" xmlns:atom=\"http://www.w3.org/2005/Atom\" version=\"2.0\"> <channel> <atom:link href=\"http://mikem-18bd0e1e.localhost.run/\" rel=\"self\" type=\"application/rss+xml\"></atom:link> <title>Sample Feed</title> <link>http://example.com</link> <language>en-us</language> <itunes:subtitle>Just a sample</itunes:subtitle> <itunes:author>Mike Miller</itunes:author> <itunes:summary>A sample feed hosted on the Internet Computer</itunes:summary> <description>A sample feed hosted on the Internet Computer</description> <itunes:owner> <itunes:name>Mike Miller</itunes:name> <itunes:email>mike@videate.org</itunes:email> </itunes:owner> <itunes:explicit>no</itunes:explicit> <itunes:image href=\"https://brianchristner.io/content/images/2016/01/Success-loading.jpg\"></itunes:image> <itunes:category text=\"Arts\"></itunes:category> <item> <title>test</title> <itunes:summary>test</itunes:summary> <description>test</description> <link>http://example.com/podcast-1</link> <enclosure url=\"https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4\" type=\"video/mpeg\" length=\"1024\"></enclosure> <pubDate>21 Dec 2016 16:01:07 +0000</pubDate> <itunes:author>Mike Miller</itunes:author> <itunes:duration>00:32:16</itunes:duration> <itunes:explicit>no</itunes:explicit> <guid></guid> </item> </channel> </rss>";
    
    // This pattern uses `preupgrade` and `postupgrade` to allow `feeds` to be
    // stable even though HashMap is not. See
    // https://sdk.dfinity.org/docs/language-guide/upgrades.html#_preupgrade_and_postupgrade_system_methods
    stable var stableCredits: StableCredits = { feedEntries = []; };
    var credits : Credits.Credits = Credits.Credits(stableCredits);

    system func preupgrade() {
        stableCredits := credits.asStable();
    };

    system func postupgrade() {
        stableCredits := { feedEntries=[]; };
    };

    /* Serve */

    public query func http_request(request : HttpRequest) : async HttpResponse {
        Debug.print("in http_request");
        // Short-circuit simple requests
        if (request.url == "/favicon.ico") {
            return {
                status_code = Nat16.fromNat(200);
                headers = [("content-type", "image/x-icon")];
                body = Text.encodeUtf8(""); // Send empty icon
                streaming_strategy = null;
            };
        } else if (request.url == "/fast") {
            // https://www.textfixer.com/tools/remove-line-breaks.php
            // https://onlinestringtools.com/escape-string
            return {
                status_code = Nat16.fromNat(200);
                headers = [("content-type", "text/xml")];
                body = Text.encodeUtf8(sampleFeed);
                streaming_strategy = null;
            };
        };

        let splitUrl = Iter.toArray(Text.split(request.url, #text("?")));
        let beforeQueryParams: Text = Text.trim(splitUrl[0], #text("/"));
        let feedKey: Text = Iter.toArray(Text.split(beforeQueryParams, #text("/")))[0];
        let episodeGuid: ?Text = if (Text.contains(beforeQueryParams, #text("/"))) {
            // The url included a path beyond just the feed key, which is
            // assumed to be the guid for an episode contained within the feed.
            let afterFirstSlash: Text = Text.trimStart(beforeQueryParams, #text(feedKey # "/"));
            Option.make(afterFirstSlash);
        } else {
            // Normal case. The url was just for the feed, not for an episode
            // within the feed.
            null;
        };

        let settingsUri = getVideateSettingsUri(request, feedKey);
        let nftPurchaseUri = getNftPurchaseUri(request, feedKey);
        let mediaHost = "videate.org";

        // Todo: Translate all media links that point to web/media to point to
        // whatever host was used in the rss request, which might be localhost
        // or a localhost.run tunnel. This can be done by setting the host to
        // the following instead: 
        //
        // let mediaHost = getRequestHost(request);
        let uriTransformers: [UriTransformer] = [
            func (input: Text): Text { Text.replace(input, #text("file:///Users/mikem/web/media/"), "https://" # mediaHost # "/"); },
        ];

        Debug.print("getting xml");

        var xml = getFeedXml(feedKey, episodeGuid, settingsUri, nftPurchaseUri, uriTransformers);
        Utils.generateFeedResponse(xml);
    };

    public shared func http_request_update(request : HttpRequest) : async HttpResponse {
        {
            status_code = 200;
            headers = [];
            body = Text.encodeUtf8("Response to " # request.method # " request (update)");
            streaming_strategy = null;
        };
    };

    private func getQueryParam(param: Text, url: Text): ?Text {
        let splitUrl = Iter.toArray(Text.split(url, #text("?")));
        let queryParamsText: Text = splitUrl[1];

        let queryParamsArray = Iter.toArray(Text.split(queryParamsText, #text("&")));
        let queryParamsPairs = Array.map<Text, (Text, Text)>(queryParamsArray, func keyAndValue { 
            let pair = Iter.toArray(Text.split(keyAndValue, #text("=")));
            return (pair[0], pair[1]);
        });

        let found = Array.find<(Text, Text)>(queryParamsPairs, func pair { pair.0 == param });
        return switch(found) {
            case null null;
            case (? f) Option.make(f.1);
        };     
    };

    private func getRequestHost(request: HttpRequest): Text {
        // Get the host from the request header so we can tell if we're
        // using localhost or a localhost.run tunnel
        let hostHeader = Array.find<(Text, Text)>(request.headers, func pair { pair.0 == "host"});
        
        // We should never get the below error text. The host header should
        // always be defined in requests.
        Option.get(hostHeader, ("host","ERROR_NO_HOST_HEADER")).1;
    };

    private func getVideateSettingsUri(request: HttpRequest, feedKey: Text): Text {
        // If this 'serve' canister is hosted on the IC, use the hard-coded IC
        // contributor_assets canister as the host for the videate settings
        // page. Otherwise, use the same host as in the request, since that
        // host should also work for the contributor_assets canister (i.e. when
        // dfx is running locally, even when accessed through localhost.run)
        let settingsBaseUri = if(Principal.toText(Principal.fromActor(this)) == "mvjun-2yaaa-aaaah-aac3q-cai")
        {
            "https://44ejt-7yaaa-aaaao-aabqa-cai.raw.ic0.app/?"
        } else { 
            let host = getRequestHost(request);

            // Parse the contributor_assets canister cid from the query params,
            // which we specify if we're locally hosting. This is necessary
            // since there's no way, from motoko, to examine
            // .dfx/local/canister_ids.json file or the generated files under
            // ../declarations to find the cid, so we have to specify it
            // manually in the url when subscribing to a feed. See
            // https://forum.dfinity.org/t/programmatically-find-the-canister-id-of-a-frontend-canister
            let contributorAssetsCid = Option.get(
                getQueryParam("contributorAssetsCid", request.url),
                "ERROR_NO_CONTRIBUTOR_ASSETS_CID_QUERY_PARAM"
            );

            "https://" # host # "/?canisterId=" # contributorAssetsCid # "&";
        };
        return settingsBaseUri # "feedKey=" # feedKey;
    };

    private func getNftPurchaseUri(request: HttpRequest, feedKey: Text): Text {
        // If this 'serve' canister is hosted on the IC, use the hard-coded IC
        // contributor_assets canister as the host for the videate settings
        // page. Otherwise, use the same host as in the request, since that
        // host should also work for the contributor_assets canister (i.e. when
        // dfx is running locally, even when accessed through localhost.run)
        let settingsBaseUri = if(Principal.toText(Principal.fromActor(this)) == "mvjun-2yaaa-aaaah-aac3q-cai")
        {
            "https://44ejt-7yaaa-aaaao-aabqa-cai.raw.ic0.app/?"
        } else { 
            let host = getRequestHost(request);

            // Parse the contributor_assets canister cid from the query params,
            // which we specify if we're locally hosting. This is necessary
            // since there's no way, from motoko, to examine
            // .dfx/local/canister_ids.json file or the generated files under
            // ../declarations to find the cid, so we have to specify it
            // manually in the url when subscribing to a feed. See
            // https://forum.dfinity.org/t/programmatically-find-the-canister-id-of-a-frontend-canister
            let contributorAssetsCid = Option.get(
                getQueryParam("contributorAssetsCid", request.url),
                "ERROR_NO_CONTRIBUTOR_ASSETS_CID_QUERY_PARAM"
            );

            "https://" # host # "/nft?canisterId=" # contributorAssetsCid # "&";
        };
        return settingsBaseUri # "feedKey=" # feedKey;
    };

    /* Credits interface */

    // Feeds
    public func addFeed(key: Text, feed : Feed) : async Nat {
        credits.addFeed(key, feed);
    };

    public func deleteFeed(key: Text){
        credits.deleteFeed(key);
    };

    public query func getAllFeedKeys() : async [Text] {
        credits.getAllFeedKeys();
    };

    public query func getAllFeeds() : async [(Text, Feed)] {
        credits.getAllFeeds();
    };

    public query func getFeed(key: Text) : async ?Feed {
        credits.getFeed(key);
    };

    public func setNftTokenId(feedKey: Text, episodeGuid: Text, tokenId: ?Nat64) : async Types.MediaSearchResult {
        credits.setNftTokenId(feedKey, episodeGuid, tokenId);
    };

    public func getFeedSummary(key: Text) : async (Text, Text) {
        credits.getFeedSummary(key);
    };

    public func getAllFeedSummaries() : async [(Text, Text)] {
        await credits.getAllFeedSummaries();
    };

    public func getFeedMediaDetails(key: Text) : async (Text, [(Text, Text)]) {
        credits.getFeedMediaDetails(key);
    };

    public func getAllFeedMediaDetails() : async [(Text, [(Text, Text)])] {
        await credits.getAllFeedMediaDetails();
    };

    public query func getSampleFeed() : async Feed {
        credits.getSampleFeed();
    };

    func getFeedXml(key: Text, episodeGuid: ?Text, videateSettingsUri: Text, nftPurchaseUri: Text, uriTransformers: [UriTransformer]) : Text {
        let feed: ?Feed = credits.getFeed(key);
        switch(feed) {
            case null "Unrecognized feed: " # key;
            case (?feed) {
                let doc: Document = Rss.format(feed, key, episodeGuid, videateSettingsUri, nftPurchaseUri, uriTransformers);
                Xml.stringifyDocument(doc);
            };
        };
    };
};
