import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Int64 "mo:base/Int8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Char "mo:base/Char";
import Blob "mo:base/Blob";
import HashMap "mo:base/HashMap";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Xml "rss/xml";
import Types "types";
import Principal "mo:base/Principal";
import CkBtcLedger "canister:ckbtc_ledger";

module {
  type Document = Xml.Document;
  type HttpRequest = Types.HttpRequest;
  type HttpResponse = Types.HttpResponse;

  type blobTuple = (Blob, Blob);

  public func generateFeedResponse(xml : Text) : HttpResponse {
    return generateResponse(200, [("content-type", "text/xml")], xml);
  };

  public func generateErrorResponse(msg : Text) : HttpResponse {
    return generateResponse(400, [("content-type", "text")], msg);
  };

  public func generateResponse(status : Nat, headers : [(Text, Text)], body : Text) : HttpResponse {
    // Translate the inputs to the expected types
    var statusNat16 = Nat16.fromNat(status);
    var bodyBlob = toBlob(body);

    var response : HttpResponse = {
      upgrade = false;
      status_code = statusNat16;
      headers = headers;
      body = bodyBlob;
      streaming_strategy = null;
    };
    return response;
  };

  public func toBlob(text : Text) : Blob {
    var wordIter = Iter.map(text.chars(), func(c : Char) : Nat32 { Char.toNat32(c) });
    var natIter = Iter.map(wordIter, func(w : Nat32) : Nat { Nat32.toNat(w) });
    // Avoid overflow by replacing all ascii characters above 126 with "~" (126)
    var sanitizedNatIter = Iter.map(natIter, func(n : Nat) : Nat { Nat.min(n, 126) });
    var nat8Iter = Iter.map(sanitizedNatIter, func(sn : Nat) : Nat8 { Nat8.fromNat(sn) });
    var nat8Array : [Nat8] = Iter.toArray(nat8Iter);
    var blob : Blob = Blob.fromArray(nat8Array);
    return blob;
  };

  // Translate an array of Text tuples into an array of tuples of Nat8 arrays
  // (for use in converting http header key/val pairs, for example)
  public func toBlobTupleArray(textTuples : [(Text, Text)]) : [blobTuple] {
    Iter.toArray(
      Iter.map(
        Iter.fromArray(textTuples),
        func(textTuple : (Text, Text)) : blobTuple {
          (toBlob(textTuple.0), toBlob(textTuple.1));
        },
      )
    );
  };

  public func textToNat(t : Text) : ?Nat {
    var n : Nat = 0;
    for (c in t.chars()) {
      if (Char.isDigit(c)) {
        let charAsNat : Nat = Nat32.toNat(Char.toNat32(c) - 48);
        n := n * 10 + charAsNat;
      } else {
        return null;
      };
    };

    return Option.make(n);
  };

  // Buffer.fromArray is documented and should exist, but errors are produced
  // so the function is duplicated here. See
  // https://forum.dfinity.org/t/buffer-fromarray-missing-from-motoko-base-lib/13746/7?u=mymikemiller
  public func bufferFromArray<X>(array : [X]) : Buffer.Buffer<X> {
    let newBuffer = Buffer.Buffer<X>(array.size());

    for (element in array.vals()) {
      newBuffer.add(element);
    };

    newBuffer;
  };

  // Similar to bufferFromArray, this function is also duplicated here to avoid
  // errors
  public func bufferToArray<X>(buffer : Buffer.Buffer<X>) : [X] =
  // immutable clone of array
  Array.tabulate<X>(
    buffer.size(),
    func(i : Nat) : X { buffer.get(i) },
  );

  public func addValueToEntry(map : HashMap.HashMap<Principal, Float>, key : Principal, value : Float) : HashMap.HashMap<Principal, Float> {
    let currentValue = Option.get(map.get(key), 0.0);
    map.put(key, currentValue + value);
    map;
  };

  public func getQueryParam(param : Text, url : Text) : ?Text {
    let splitUrl = Iter.toArray(Text.split(url, #text("?")));

    if (splitUrl.size() == 1) {
      return null;
    };

    let queryParamsText : Text = splitUrl[1];

    let queryParamsArray = Iter.toArray(Text.split(queryParamsText, #text("&")));
    let queryParamsPairs = Array.map<Text, (Text, Text)>(
      queryParamsArray,
      func keyAndValue {
        let pair = Iter.toArray(Text.split(keyAndValue, #text("=")));
        return (pair[0], pair[1]);
      },
    );

    let found = Array.find<(Text, Text)>(
      queryParamsPairs,
      func pair { pair.0 == param },
    );
    return switch (found) {
      case null null;
      case (?f) Option.make(f.1);
    };
  };

  /// Convert Principal to ICRC1.Subaccount
  // from https://github.com/research-ag/motoko-lib/blob/2772d029c1c5087c2f57b022c84882f2ac16b79d/src/TokenHandler.mo#L51
  public func toSubaccount(p : Principal) : Types.Subaccount {
    // p blob size can vary, but 29 bytes as most. We preserve it'subaccount size in result blob
    // and it'subaccount data itself so it can be deserialized back to p
    let bytes = Blob.toArray(Principal.toBlob(p));
    let size = bytes.size();

    assert size <= 29;

    let a = Array.tabulate<Nat8>(
      32,
      func(i : Nat) : Nat8 {
        if (i + size < 31) {
          0;
        } else if (i + size == 31) {
          Nat8.fromNat(size);
        } else {
          bytes[i + size - 32];
        };
      },
    );
    Blob.fromArray(a);
  };

  public func toAccount({ caller : Principal; canister : Principal }) : Types.Account {
    {
      owner = canister;
      subaccount = ?toSubaccount(caller);
    };
  };
};
