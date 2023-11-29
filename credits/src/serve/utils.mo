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

  public func toLowercase(str : Text) : Text {
    return Text.map(
      str,
      func(char : Char) {
        // Ascii difference between lower and upper case is 32
        if (Char.isUppercase(char)) Char.fromNat32(Char.toNat32(char) + 32) else char;
      },
    );
  };

  public func pushOrMoveToTop(array : [Text], element : Text) : [Text] {
    let buffer = Buffer.Buffer<Text>(array.size());
    // Add the new element to the top of the list
    buffer.add(element);
    // Now add everything else, skipping the element we just added
    Iter.iterate(
      array.vals(),
      func(e : Text, _index : Nat) {
        // Skip the new item so we don't store it twice
        if (e != element) {
          buffer.add(e);
        };
      },
    );
    let newArray = Buffer.toArray<Text>(buffer);
    return newArray;
  };

  // This function is necessary because motoko lacks support for regular
  // expressions. When support is added, this RegExp can be used:
  // /^[a-z0-9-]*$/
  public func isValidFeedKey(str : Text) : Bool {
    // Only lowercase characters, numbers and dashes are allowed
    let allowed = "abcdefghijklmnopqrstuvwxyz0123456789-";
    for (c in str.chars()) {
      if (not Text.contains(allowed, #char c)) {
        return false;
      };
    };
    return true;
  };

};
