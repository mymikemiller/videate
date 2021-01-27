
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
        var xml = await getFeedXml();
        var response = await Utils.generateFeedResponse(xml);
        Debug.print("Returning feed response");
        return response;
    };

    public func getFeedXml() : async Text {
        let feed: Feed = await Credits.getSampleFeed();
        let doc: Document = await Rss.format(feed);
        let xml: Text = Xml.stringifyDocument(doc);
        return xml;
    };
};
