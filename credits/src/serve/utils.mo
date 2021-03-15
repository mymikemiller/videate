import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Word32 "mo:base/Word32";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Xml "xml";
import Types "types";

module {
    type Document = Xml.Document;
    type Request = Types.Request;
    type Response = Types.Response;
    
    type nat8ArrayTuple = ([Nat8], [Nat8]);

    public func generateUpgradeResponse() : async Response {
        generateResponse(200, [("content-type", "text/plain")], "Upgrading to non-query call", true);
    };

    public func generateFeedResponse(xml: Text) : Response {
        return generateResponse(200, [("content-type", "text/xml")], xml, false);
    };

    public func generateResponse(status: Nat, headers: [(Text, Text)], body: Text, upgrade: Bool): Response {
        // Translate the inputs to the expected types
        var statusNat16 = Nat16.fromNat(status);
        var bodyNat8Array = toNat8Array(body);
        var headersNat8 = toNat8ArrayTupleArray(headers);
        
        var response: Response = {
            status = statusNat16;
            headers = headersNat8;
            body = bodyNat8Array;
            upgrade = upgrade;
        };
        return response;
    };

    public func toNat8Array(text: Text): [Nat8] {
        var wordIter = Iter.map(text.chars(), func(c : Char) : Word32 { Char.toWord32(c) });
        var natIter = Iter.map(wordIter, func(w : Word32) : Nat { Word32.toNat(w) });
        var nat8Iter = Iter.map(natIter, func(n : Nat) : Nat8 { Nat8.fromNat(n) });
        return Iter.toArray(nat8Iter);
    };

    // Translate an array of Text tuples into an array of tuples of Nat8 arrays
    // (for use in converting http header key/val pairs, for example)
    public func toNat8ArrayTupleArray(textTuples: [(Text, Text)]) : [nat8ArrayTuple] {
        Iter.toArray(
            Iter.map(
                Iter.fromArray(textTuples), 
                func(textTuple : (Text, Text)) : nat8ArrayTuple { 
                    (toNat8Array(textTuple.0), toNat8Array(textTuple.1))
                }
            )
        );
    }

}
