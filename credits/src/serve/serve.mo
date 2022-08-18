import Array "mo:base/Array";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat64 "mo:base/Nat64";
import Char "mo:base/Char";
import List "mo:base/List";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import HashMap "mo:base/HashMap";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Credits "credits/credits";
import Contributors "contributors/contributors";
import NftDb "nft_db/nft_db";
import Rss "rss/rss";
import Xml "rss/xml";
import Types "types";
import Utils "utils";

actor class Serve() = Self {
  type HttpRequest = Types.HttpRequest;
  type HttpResponse = Types.HttpResponse;
  type StableCredits = Credits.StableCredits;
  type MediaSearchResult = Credits.MediaSearchResult;
  type StableContributors = Contributors.StableContributors;
  type ContributorsError = Contributors.Error;
  type Contributors = Contributors.Error;
  type Feed = Credits.Feed;
  type Document = Xml.Document;
  type UriTransformer = Types.UriTransformer;
  type Media = Credits.Media;
  type OwnerResult = NftDb.OwnerResult;
  type Profile = Contributors.Profile;
  type ProfileUpdate = Contributors.ProfileUpdate;
  type BuyNftResult = Contributors.BuyNftResult;
  type ApiError = NftDb.ApiError;
  type SearchError = Credits.SearchError;
  type MintReceiptPart = NftDb.MintReceiptPart;
  type MintReceipt = NftDb.MintReceipt;

  let sampleFeed = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> <rss xmlns:itunes=\"http://www.itunes.com/dtds/podcast-1.0.dtd\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\" xmlns:atom=\"http://www.w3.org/2005/Atom\" version=\"2.0\"> <channel> <atom:link href=\"http://mikem-18bd0e1e.localhost.run/\" rel=\"self\" type=\"application/rss+xml\"></atom:link> <title>Sample Feed</title> <link>http://example.com</link> <language>en-us</language> <itunes:subtitle>Just a sample</itunes:subtitle> <itunes:author>Mike Miller</itunes:author> <itunes:summary>A sample feed hosted on the Internet Computer</itunes:summary> <description>A sample feed hosted on the Internet Computer</description> <itunes:owner> <itunes:name>Mike Miller</itunes:name> <itunes:email>mike@videate.org</itunes:email> </itunes:owner> <itunes:explicit>no</itunes:explicit> <itunes:image href=\"https://brianchristner.io/content/images/2016/01/Success-loading.jpg\"></itunes:image> <itunes:category text=\"Arts\"></itunes:category> <item> <title>test</title> <itunes:summary>test</itunes:summary> <description>test</description> <link>http://example.com/podcast-1</link> <enclosure url=\"https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4\" type=\"video/mpeg\" length=\"1024\"></enclosure> <pubDate>21 Dec 2016 16:01:07 +0000</pubDate> <itunes:author>Mike Miller</itunes:author> <itunes:duration>00:32:16</itunes:duration> <itunes:explicit>no</itunes:explicit> <guid></guid> </item> </channel> </rss>";
  
  // This pattern uses `preupgrade` and `postupgrade` to allow `feeds` to be
  // stable even though HashMap is not. See
  // https://sdk.dfinity.org/docs/language-guide/upgrades.html#_preupgrade_and_postupgrade_system_methods
  stable var stableCredits: StableCredits = { feedEntries = []; };
  var credits : Credits.Credits = Credits.Credits(stableCredits);
  stable var stableContributors: StableContributors = { profileEntries = []; };
  var contributors : Contributors.Contributors = Contributors.Contributors(stableContributors);

  // nftDb can be stable since it does not have functions that manipulate its
  // own data
  stable var nftDb: NftDb.NftDb = NftDb.NftDb();

  system func preupgrade() {
    stableCredits := credits.asStable();
    stableContributors := contributors.asStable();
  };

  system func postupgrade() {
    stableCredits := { feedEntries=[]; };
    stableContributors := { profileEntries=[]; };
  };

  /* Serve */

  public query func http_request(request : HttpRequest) : async HttpResponse {
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
    if (beforeQueryParams == "") {
      return Utils.generateErrorResponse("No feed key specified. Expected URL format: <cid>.<host>:<port>/feed_key?principal=...");
    };
    let feedKey: Text = Iter.toArray(Text.split(beforeQueryParams, #text("/")))[0];

    let requestorPrincipal = getQueryParam("principal", request.url);
    let episodeGuid = getQueryParam("episodeGuid", request.url);
  
    let frontendUri = getFrontendUri(request);

    let mediaHost = "videate.org";

    // Todo: Translate all media links that point to web/media to point to
    // whatever host was used in the rss request, which might be localhost or a
    // localhost.run tunnel. This can be done by setting the host to the
    // following instead: 
    //
    // let mediaHost = getRequestHost(request);
    let uriTransformers: [UriTransformer] = [
      func (input: Text): Text { Text.replace(input, #text("file:///Users/mikem/web/media/"), "https://" # mediaHost # "/"); },
    ];

    var xml = getFeedXml(feedKey, episodeGuid, requestorPrincipal, frontendUri, contributors, nftDb, uriTransformers);

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

    if (splitUrl.size() == 1) {
      return null;
    };

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
    // Get the host from the request header so we can tell if we're using
    // localhost or a localhost.run tunnel
    let hostHeader = Array.find<(Text, Text)>(request.headers, func pair { pair.0 == "host"});
    
    // We should never get the below error text. The host header should always
    // be defined in requests.
    Option.get(hostHeader, ("host","ERROR_NO_HOST_HEADER")).1;
  };

  private func getFrontendUri(request: HttpRequest): Text {
    // If this 'serve' canister is hosted on the IC, use the hard-coded IC
    // frontend canister as the host for the videate settings page. Otherwise,
    // use the same host as in the request, since that host should also work
    // for the frontend canister (i.e. when dfx is running locally, even when
    // accessed through localhost.run)
    let thisActorCid = Principal.toText(Principal.fromActor(Self));
    let baseUri = if(thisActorCid == "mvjun-2yaaa-aaaah-aac3q-cai")
    {
      // Hard-code the IC network frontend cid if we're responding
      // from within the IC network serve canister
      "https://44ejt-7yaaa-aaaao-aabqa-cai.raw.ic0.app"
    } else { 
      // Parse the frontend canister cid from the query params, which we
      // specify if we're locally hosting. This is necessary since there's no
      // way, from motoko, to examine .dfx/local/canister_ids.json file or the
      // generated files under ../declarations to find the cid, so we have to
      // specify it manually in the url when subscribing to a feed. See
      // https://forum.dfinity.org/t/programmatically-find-the-canister-id-of-a-frontend-canister
      let frontendCid = Option.get(
        getQueryParam("frontendCid", request.url),
        "ERROR_NO_FRONTEND_CID_QUERY_PARAM"
      );

      // Replace this server's cid in the host with the frontend cid
      let requestHost = getRequestHost(request);
      let correctedUri = Text.replace(requestHost, #text(thisActorCid), frontendCid);

      // If the 'port' query param was specified, use that port for frontend
      // urls. This way we can generate links to the hot-reload enabled
      // frontend running on port 3000 in cases where this server is on running
      // port 8000.
      let port = Option.get(
        getQueryParam("port", request.url),
        "8000"
      );
      Text.replace(correctedUri, #text(":8000"), ":" # port);
    };
    return baseUri;
  };

  /* Public Application interface */

  // Mint or transfer the NFT for the given episode into the logged-in user
  // (msg.caller)'s name
  public shared(msg) func buyNft(feedKey: Text, media: Media) : async BuyNftResult {
    if (not NftDb.isInitialized(nftDb)) {
      Debug.print("NftDb module is uninitialized. Please execute `dfx canister call serve initializeNftDb` after initial deploy.");
      return #Err(#ApiError(#Other("NftDb module has not been initialized. See dfx output for details.")));
    };

    switch(media.nftTokenId) {
      case (? tokenId) {
        // The NFT's been minted already, do a transfer
        let currentOwner = switch(NftDb.ownerOfDip721(nftDb, tokenId)) {
          case (#Ok(currentOwnerPrincipal: Principal)) {
            currentOwnerPrincipal;
          };
          case (#Err(e: ApiError)) {
            return #Err(#ApiError(e));
          };
        };
      
        let txReceipt : NftDb.TxReceipt = NftDb.safeTransferFromDip721(
          nftDb,
          /* Caller. Note that to transfer, we can't pass msg.caller because
          that refers to the logged-in new owner, not the previous owner who is
          the only one who has the right to transfer their NFT (except for this
          actor, which was made a custodian when this canister was initialized)
          */
          Principal.fromActor(Self), 
          currentOwner, /* From */
          msg.caller, /* To */
          tokenId);

        switch(txReceipt) {
          case (#Ok(transactionId : Nat)) {
            return #Ok(#TransferTransactionId(transactionId));
          };
          case (#Err(e: ApiError)) {
            return #Err(#ApiError(e));
          }
        };
      };
      case (null) {
        // The NFT for the Media hasn't been minted yet. Mint it.
        let metadata: [NftDb.MetadataPart] = [
          {
            purpose = #Rendered;
            key_val_data = [
              {
                key = "description"; 
                val = #TextContent ("Episode of a Videate podcast");
              },
              {
                key = "tag"; 
                val = #TextContent ("episode");
              },
              {
                key = "contentType";
                val = #TextContent ("text/plain");
              },
              {
                key = "locationType"; 
                val = #Nat8Content (4);
              }
            ];
            data = Text.encodeUtf8("https://rss.videate.org/" # feedKey # "&episodeGuid=" # media.uri); // For now, assume the media uri is the guid
          }
        ];
        let mintReceipt : MintReceipt = NftDb.mintDip721(
          nftDb, 
          Principal.fromActor(Self), // Caller
          msg.caller,                // Owner of newly minted NFT
          metadata);

        switch(mintReceipt) {
          case (#Ok(mintReceiptPart: MintReceiptPart)) {
            // Associate the Media with the new tokenId
            let setNftTokenIdResult : MediaSearchResult = credits.setNftTokenId(feedKey, media.uri, mintReceiptPart.token_id); // For now, assume the media uri is the guid
            switch(setNftTokenIdResult) {
              case (#Ok(_: Credits.Media)) {
                return #Ok(#MintReceiptPart(mintReceiptPart));
              };
              case (#Err(e: SearchError)) {
                return #Err(#SearchError(e));
              };
            };
          };
          case (#Err(e : ApiError)) {
            return #Err(#ApiError(e));
          };
        };
      };
    };
  };

  /* Credits interface */

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

  func getFeedXml(key: Text, episodeGuid: ?Text, requestorPrincipal: ?Text, frontendUri: Text, contributors: Contributors.Contributors, nftDb: NftDb.NftDb, uriTransformers: [UriTransformer]) : Text {
    let feed: ?Feed = credits.getFeed(key);
    switch(feed) {
      case null Xml.stringifyError("Unrecognized feed: " # key);
      case (?feed) {
        let doc: Document = Rss.format(feed, key, episodeGuid, requestorPrincipal, frontendUri, contributors, nftDb, uriTransformers);
        Xml.stringifyDocument(doc);
      };
    };
  };

  /* Contributors interface */

  public func getContributorName(principal: Principal) : async ?Text {
    contributors.getName(principal);
  };
  public shared(msg) func addRequestedFeedKey(feedKey: Text) : async Result.Result<Profile, Contributors.Error> {
    contributors.addRequestedFeedKey(msg.caller, feedKey);
  };
  public shared(msg) func createContributor(profile: Contributors.ProfileUpdate) : async Result.Result<(), Contributors.Error> {
    contributors.create(msg.caller, profile);
  };
  public shared(msg) func readContributor() : async Result.Result<Profile, Contributors.Error> {
    contributors.read(msg.caller);
  };
  public shared(msg) func updateContributor(profile : ProfileUpdate) : async Result.Result<(), Contributors.Error> {
    contributors.update(msg.caller, profile);
  };
  public shared(msg) func deleteContributor() : async Result.Result<(), Contributors.Error> {
    contributors.delete(msg.caller);
  };

  /* nft interface */
  
  public query func balanceOfDip721(user: Principal) : async Nat64 {
    NftDb.balanceOfDip721(nftDb, user);
  };

  public query func ownerOfDip721(token_id: NftDb.TokenId) : async NftDb.OwnerResult {
    NftDb.ownerOfDip721(nftDb, token_id);
  };

  public shared({ caller }) func safeTransferFromDip721(from: Principal, to: Principal, token_id: NftDb.TokenId) : async NftDb.TxReceipt {  
    NftDb.safeTransferFromDip721(nftDb, caller, from, to, token_id);
  };

  public shared({ caller }) func transferFromDip721(from: Principal, to: Principal, token_id: NftDb.TokenId) : async NftDb.TxReceipt {
    NftDb.transferFromDip721(nftDb, caller, from, to, token_id);
  };

  public query func supportedInterfacesDip721() : async [NftDb.InterfaceId] {
    NftDb.supportedInterfacesDip721();
  };

  public query func logoDip721() : async NftDb.LogoResult {
    NftDb.logoDip721(nftDb);
  };

  public query func nameDip721() : async Text {
    NftDb.nameDip721(nftDb);
  };

  public query func symbolDip721() : async Text {
    NftDb.symbolDip721(nftDb);
  };

  public query func totalSupplyDip721() : async Nat64 {
    NftDb.totalSupplyDip721(nftDb);
  };

  public query func getMetadataDip721(token_id: NftDb.TokenId) : async NftDb.MetadataResult {
    NftDb.getMetadataDip721(nftDb, token_id);
  };

  public query func getMaxLimitDip721() : async Nat16 {
    NftDb.getMaxLimitDip721(nftDb);
  };

  public func getMetadataForUserDip721(user: Principal) : async NftDb.ExtendedMetadataResult {
    NftDb.getMetadataForUserDip721(nftDb, user);
  };

  public query func getTokenIdsForUserDip721(user: Principal) : async [NftDb.TokenId] {
    NftDb.getTokenIdsForUserDip721(nftDb, user);
  };

  public shared({ caller }) func mintDip721(to: Principal, metadata: NftDb.MetadataDesc) : async MintReceipt {
    NftDb.mintDip721(nftDb, caller, to, metadata);
  };

  public shared({ caller }) func addNftCustodian(newCustodian: Principal) : async NftDb.Result<(), ApiError> {
    NftDb.addCustodian(nftDb, caller, newCustodian);
  };
  
  public shared({ caller }) func initializeNftDb() : async NftDb.Result<(), ApiError> {
    // Add the caller as the first custodian. This gives all rights to the
    // person who deployed this canister, as long as they make the first
    // initializeNftDb call. Note that this call will fail if the canister
    // already has a custodian; this method can only be called on an
    // uninitialized nftDb object.
    let result = NftDb.addCustodian(nftDb, caller, caller);
    switch(result) {
      case (#Ok()) {
        // continue
      };
      case (#Err(e)) {
        return result;
      };
    };

    // Also add this canister as a custodian, without which this canister
    // wouldn't be able to mint or transfer NFTs
    NftDb.addCustodian(nftDb, caller, Principal.fromActor(Self));
  };
};
