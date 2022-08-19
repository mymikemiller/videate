import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Char "mo:base/Char";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Xml "rss/xml";
import Types "types";

module {
    type Document = Xml.Document;
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;
    
    type blobTuple = (Blob, Blob);

    public func generateFeedResponse(xml: Text) : HttpResponse {
        return generateResponse(200, [("content-type", "text/xml")], xml);
    };

    public func generateErrorResponse(msg: Text) : HttpResponse {
        return generateResponse(400, [("content-type", "text")], msg);
    };

    public func generateResponse(status: Nat, headers: [(Text, Text)], body: Text): HttpResponse {
        // Translate the inputs to the expected types
        var statusNat16 = Nat16.fromNat(status);
        var bodyBlob = toBlob(body);
        
        var response: HttpResponse = {
            status_code = statusNat16;
            headers = headers;
            body = bodyBlob;
            streaming_strategy = null;
        };
        return response;
    };

    public func toBlob(text: Text): Blob {
        var wordIter = Iter.map(text.chars(), func(c : Char) : Nat32 { Char.toNat32(c) });
        var natIter = Iter.map(wordIter, func(w : Nat32) : Nat { Nat32.toNat(w) });
        // Avoid overflow by replacing all ascii characters above 126 with "~" (126)
        var sanitizedNatIter = Iter.map(natIter, func(n : Nat) : Nat { Nat.min(n, 126) });
        var nat8Iter = Iter.map(sanitizedNatIter, func(sn : Nat) : Nat8 { Nat8.fromNat(sn) });
        var nat8Array: [Nat8] = Iter.toArray(nat8Iter);
        var blob: Blob = Blob.fromArray(nat8Array);
        return blob;
    };

    // Translate an array of Text tuples into an array of tuples of Nat8 arrays
    // (for use in converting http header key/val pairs, for example)
    public func toBlobTupleArray(textTuples: [(Text, Text)]) : [blobTuple] {
        Iter.toArray(
            Iter.map(
                Iter.fromArray(textTuples), 
                func(textTuple : (Text, Text)) : blobTuple { 
                    (toBlob(textTuple.0), toBlob(textTuple.1))
                }
            )
        );
    }

}
