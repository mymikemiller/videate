import NftTypes "nft_db/types";
import CreditsTypes "credits/types";
import ContributorsTypes "contributors/types";
import Result "mo:base/Result";

module {
  /* Serve */
  public type HeaderField = (Text, Text);

  public type Token = {};

  // A CkSat, Chain Key Satoshi, is the BTC value * 10^8 so it can be
  // represented as a Nat. This is because CkBtcLedger reports "8" for
  // icrc1_decimals (basically it uses Satoshi instead of BTC)
  public type CkSat = Nat;

  public type StreamingCallbackHttpResponse = {
    body : Blob;
    token : Token;
  };

  public type StreamingStrategy = {
    #Callback : {
      callback : shared Token -> async StreamingCallbackHttpResponse;
      token : Token;
    };
  };

  public type HttpRequest = {
    method : Text;
    headers : [HeaderField];
    url : Text;
    body : Blob;
  };

  public type HttpResponse = {
    upgrade : Bool;
    status_code : Nat16;
    headers : [HeaderField];
    body : Blob;
    streaming_strategy : ?StreamingStrategy;
  };

  public type UriTransformer = Text -> Text;

  public type ServeError = {
    #NftError : NftTypes.NftError;
    #CreditsError : CreditsTypes.CreditsError;
    #ContributorsError : ContributorsTypes.ContributorsError;
  };

  // PutFeedFullResult differs from Credits.PutResult in that it might result
  // in an error when updating the contributor's list of owned feeds.
  public type PutFeedFullResult = Result.Result<CreditsTypes.PutSuccess, { #CreditsError : CreditsTypes.CreditsError; #ContributorsError : ContributorsTypes.ContributorsError }>;

  // Information describing the amount in Satoshis distributed to each user.
  // [User's Principal, user's name, amount]
  public type DistributionAmounts = [(Principal, ?Text, CkSat)];

  public type Subaccount = Blob;
  public type Account = {
    owner : Principal;
    subaccount : ?Subaccount;
  };
  public type Invoice = {
    to : Account;
    amount : Nat;
  };
};
