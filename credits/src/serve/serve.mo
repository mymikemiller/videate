import Array "mo:base/Array";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
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
  type EpisodeSearchResult = Credits.EpisodeSearchResult;
  type PutFeedFullResult = Types.PutFeedFullResult;
  type StableContributors = Contributors.StableContributors;
  type Feed = Credits.Feed;
  type FeedKey = Credits.FeedKey;
  type Document = Xml.Document;
  type UriTransformer = Types.UriTransformer;
  type Media = Credits.Media;
  type MediaData = Credits.MediaData;
  type MediaID = Credits.MediaID;
  type Episode = Credits.Episode;
  type EpisodeID = Credits.EpisodeID;
  type EpisodeData = Credits.EpisodeData;
  type OwnerResult = NftDb.OwnerResult;
  type Profile = Contributors.Profile;
  type ProfileResult = Contributors.ProfileResult;
  type ProfileUpdate = Contributors.ProfileUpdate;
  type BuyNftResult = Contributors.BuyNftResult;
  type NftError = NftDb.NftError;
  type ServeError = Types.ServeError;
  type CreditsError = Credits.CreditsError;
  type ContributorsError = Contributors.ContributorsError;
  type MintReceiptPart = NftDb.MintReceiptPart;
  type MintReceipt = NftDb.MintReceipt;

  let sampleFeed = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> <rss xmlns:itunes=\"http://www.itunes.com/dtds/podcast-1.0.dtd\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\" xmlns:atom=\"http://www.w3.org/2005/Atom\" version=\"2.0\"> <channel> <atom:link href=\"http://mikem-18bd0e1e.localhost.run/\" rel=\"self\" type=\"application/rss+xml\"></atom:link> <title>Sample Feed</title> <link>http://example.com</link> <language>en-us</language> <itunes:subtitle>Just a sample</itunes:subtitle> <itunes:author>Mike Miller</itunes:author> <itunes:summary>A sample feed hosted on the Internet Computer</itunes:summary> <description>A sample feed hosted on the Internet Computer</description> <itunes:owner> <itunes:name>Mike Miller</itunes:name> <itunes:email>mike@videate.org</itunes:email> </itunes:owner> <itunes:explicit>no</itunes:explicit> <itunes:image href=\"https://brianchristner.io/content/images/2016/01/Success-loading.jpg\"></itunes:image> <itunes:category text=\"Arts\"></itunes:category> <item> <title>test</title> <itunes:summary>test</itunes:summary> <description>test</description> <link>http://example.com/podcast-1</link> <enclosure url=\"https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4\" type=\"video/mpeg\" length=\"1024\"></enclosure> <pubDate>21 Dec 2016 16:01:07 +0000</pubDate> <itunes:author>Mike Miller</itunes:author> <itunes:duration>00:32:16</itunes:duration> <itunes:explicit>no</itunes:explicit> <guid></guid> </item> </channel> </rss>";

  // This pattern uses `preupgrade` and `postupgrade` to allow `feeds` to be
  // stable even though HashMap and Buffer are not. See
  // https://sdk.dfinity.org/docs/language-guide/upgrades.html#_preupgrade_and_postupgrade_system_methods
  stable var stableCredits : StableCredits = {
    feedEntries = [];
    episodeEntries = [];
    mediaEntries = [];
    custodianEntries = [];
  };
  var credits : Credits.Credits = Credits.Credits(stableCredits);
  stable var stableContributors : StableContributors = { profileEntries = [] };
  var contributors : Contributors.Contributors = Contributors.Contributors(stableContributors);

  // nftDb can be stable since it does not have functions that manipulate its
  // own data
  stable var nftDb : NftDb.NftDb = NftDb.NftDb();

  system func preupgrade() {
    stableCredits := credits.asStable();
    stableContributors := contributors.asStable();
  };

  system func postupgrade() {
    stableCredits := {
      feedEntries = [];
      episodeEntries = [];
      mediaEntries = [];
      custodianEntries = [];
    };
    stableContributors := { profileEntries = [] };
  };

  /* Serve */

  public query func http_request(request : HttpRequest) : async HttpResponse {
    // Short-circuit simple requests
    if (request.url == "/favicon.ico") {
      return {
        upgrade = false;
        status_code = Nat16.fromNat(200);
        headers = [("content-type", "image/x-icon")];
        body = Text.encodeUtf8(""); // Send empty icon
        streaming_strategy = null;
      };
    } else if (request.url == "/fast") {
      // https://www.textfixer.com/tools/remove-line-breaks.php
      // https://onlinestringtools.com/escape-string
      return {
        upgrade = false;
        status_code = Nat16.fromNat(200);
        headers = [("content-type", "text/xml")];
        body = Text.encodeUtf8(sampleFeed);
        streaming_strategy = null;
      };
    };

    // Attempt to parse the feed early, since we may trap there and won't need
    // to bother upgrading the request
    let feed : Feed = _parseFeed(request);

    if (_isMediaRequest(request)) {
      // Upgrade to an update call so we can track access and redirect to the
      // media file. Note that we don't use a 303 redirect here like could be
      // expected. Instead we use a 200 code and upgrade, and perform the
      // tracking and 303 redirect in http_request_update below. See
      // https://forum.dfinity.org/t/changes-regarding-redirect-handling-by-the-service-worker/15047
      return {
        upgrade = true;
        status_code = Nat16.fromNat(200);
        headers = [];
        body = "";
        streaming_strategy = null;
      };
    };

    let requestorPrincipal : ?Text = _parsePrincipal(request);
    let episodeId : ?Nat = _parseEpisodeId(request);
    let frontendUri : Text = _parseFrontendUri(request);
    var feedUri : Text = _parseHost(request) # "/" # feed.key;

    // If the request host didn't include the canister id, we need to
    // insert it as a query param. This is necessary for cases when the
    // host is, for example, ssh'd through localhost.run where subdomains
    // (which would normally contain the cid) don't work
    let thisActorCid = Principal.toText(Principal.fromActor(Self));
    if (not Text.contains(feedUri, #text(thisActorCid))) {
      feedUri := feedUri # "?canisterId=" # thisActorCid;
    };

    var xml = getFeedXml(
      feed,
      episodeId,
      requestorPrincipal,
      frontendUri,
      feedUri,
      contributors,
      nftDb,
    );

    Utils.generateFeedResponse(xml);
  };

  public shared func http_request_update(request : HttpRequest) : async HttpResponse {
    // Verify that we are requesting a media file, as that is the only way the
    // request should have been upgraded to an update call (we don't currently
    // track feed requests, so those don't get upgraded)
    if (not _isMediaRequest(request)) {
      Debug.trap("Error: non-media request was upgraded to an update call");
    };

    let feed : Feed = _parseFeed(request);
    let episodeId : Nat = switch (_parseEpisodeId(request)) {
      case null Debug.trap("Media request did not specify episode");
      case (?episodeId) episodeId;
    };
    let episode : Episode = switch (credits.getEpisode(feed.key, episodeId)) {
      case null Debug.trap("Episode not found in feed. Feed: " # feed.key # ", episode: " # Nat.toText(episodeId));
      case (?episode) episode;
    };
    let media : Media = switch (credits.getMedia(episode.mediaId)) {
      case null Debug.trap("Media not found. mediaId: " # Nat.toText(episode.mediaId));
      case (?media) media;
    };

    // Transform the actual URL before redirecting
    let mediaHost = _parseHost(request);
    let uriTransformers : [UriTransformer] = [
      func(input : Text) : Text {
        // Translate all media links that point to /web/media to point to
        // whatever host was used in the request, which might be localhost or a
        // localhost.run tunnel
        Text.replace(
          input,
          #text("file:///Users/mikem/web/media/"),
          "https://" # mediaHost # "/",
        );
      },
    ];
    let transformedMediaUri = transformUri(media.uri, uriTransformers);

    // Redirect to the actual media file location
    return {
      upgrade = false;
      status_code = Nat16.fromNat(303); // 303 is "See Other" redirect
      headers = [("Location", transformedMediaUri)];
      body = "";
      streaming_strategy = null;
    };
  };

  private func _parseHost(request : HttpRequest) : Text {
    // Get the host from the request header so we can tell if we're using
    // localhost or a localhost.run tunnel
    let hostHeader = Array.find<(Text, Text)>(
      request.headers,
      func pair { pair.0 == "host" },
    );

    // We should never get the below error text. The host header should always
    // be defined in requests.
    "http://" # Option.get(hostHeader, ("host", "ERROR_NO_HOST_HEADER")).1;
  };

  private func _parseFrontendUri(request : HttpRequest) : Text {
    // If this 'serve' canister is hosted on the IC, use the hard-coded IC
    // frontend canister as the host for the videate settings page. Otherwise,
    // use the same host as in the request, since that host should also work
    // for the frontend canister (i.e. when dfx is running locally, even when
    // accessed through localhost.run)
    let thisActorCid = Principal.toText(Principal.fromActor(Self));
    let baseUri = if (thisActorCid == "mvjun-2yaaa-aaaah-aac3q-cai") {
      // Hard-code the IC network frontend url if we're responding
      // from within the IC network serve canister
      "https://44ejt-7yaaa-aaaao-aabqa-cai.ic0.app";
    } else {
      // Parse the frontend canister cid from the query params, which we
      // specify if we're locally hosting. This is necessary since there's no
      // way, from motoko, to examine .dfx/local/canister_ids.json file or the
      // generated files under ../declarations to find the cid, so we have to
      // specify it manually in the url when subscribing to a feed. See
      // https://forum.dfinity.org/t/programmatically-find-the-canister-id-of-a-frontend-canister
      let frontendCid = Option.get(
        Utils.getQueryParam("frontendCid", request.url),
        "ERROR_NO_FRONTEND_CID_QUERY_PARAM",
      );

      // Replace this server's cid in the host with the frontend cid
      let requestHost = _parseHost(request);
      let correctedUri = Text.replace(
        requestHost,
        #text(thisActorCid),
        frontendCid,
      );

      // If the 'port' query param was specified, use that port for frontend
      // urls. This way we can generate links to the hot-reload enabled
      // frontend running on port 3000 in cases where this server is on running
      // port 8000.
      let port = Option.get(
        Utils.getQueryParam("port", request.url),
        "8000",
      );
      Text.replace(correctedUri, #text(":8000"), ":" # port);
    };
    return baseUri;
  };

  func _parseFeed(request : HttpRequest) : Feed {
    let splitUrl = Iter.toArray(Text.split(request.url, #text("?")));
    let beforeQueryParams : Text = Text.trim(splitUrl[0], #text("/"));
    if (beforeQueryParams == "") {
      Debug.trap("No feed key specified. Expected URL format: <cid>.<host>:<port>/{feed_key}?principal=... Actual url received: " # request.url);
    };
    let feedKey : Text = Iter.toArray(Text.split(beforeQueryParams, #text("/")))[0];

    let feed : ?Feed = credits.getFeed(feedKey);
    switch (feed) {
      case null Debug.trap("Unrecognized feed: " # feedKey);
      case (?feed) feed;
    };
  };

  func _parsePrincipal(request : HttpRequest) : ?Text {
    Utils.getQueryParam("principal", request.url);
  };

  func _parseEpisodeId(request : HttpRequest) : ?Nat {
    let episodeIdAsText : ?Text = Utils.getQueryParam("episode", request.url);
    let episodeId : ?Nat = switch (episodeIdAsText) {
      case null null;
      case (?t) {
        switch (Utils.textToNat(t)) {
          case null Debug.trap("Failed to parse episode number: " # t);
          case (num) num;
        };
      };
    };
  };

  func _isMediaRequest(request : HttpRequest) : Bool {
    let requestingMediaFile : ?Text = Utils.getQueryParam("media", request.url);
    switch (requestingMediaFile) {
      case null false;
      case (?requestingMediaFile) requestingMediaFile == "true" or requestingMediaFile == "True" or requestingMediaFile == "TRUE";
    };
  };

  /* Public Application interface */

  // Mint or transfer the NFT for the given episode into the logged-in user
  // (msg.caller)'s name
  public shared (msg) func buyNft(episode : Episode) : async BuyNftResult {
    if (not NftDb.isInitialized(nftDb)) {
      Debug.print("Serve canister is uninitialized. Please execute `dfx canister call serve initialize` after initial deploy.");
      return #err(#NftError(#Uninitialized("Nft module has not been initialized. See dfx output for details.")));
    };

    switch (episode.nftTokenId) {
      case (?tokenId) {
        // The NFT's been minted already, do a transfer
        let currentOwner = switch (NftDb.ownerOfDip721(nftDb, tokenId)) {
          case (#ok(currentOwnerPrincipal : Principal)) {
            currentOwnerPrincipal;
          };
          case (#err(e : NftError)) {
            return #err(#NftError(e));
          };
        };

        let txReceipt : NftDb.TxReceipt = NftDb.safeTransferFromDip721(
          nftDb,
          // Caller. Note that to transfer, we can't pass msg.caller because
          // that refers to the logged-in new owner, not the previous owner who is
          // the only one who has the right to transfer their NFT (except for this
          // actor, which was made a custodian when this canister was initialized)
          Principal.fromActor(Self),
          // From
          currentOwner,
          // To
          msg.caller,
          tokenId,
        );

        switch (txReceipt) {
          case (#ok(transactionId : Nat)) {
            return #ok(#TransferTransactionId(transactionId));
          };
          case (#err(e : NftError)) {
            return #err(#NftError(e));
          };
        };
      };
      case (null) {
        // The NFT for the Episode hasn't been minted yet. Mint it.
        let metadata : [NftDb.MetadataPart] = [
          {
            purpose = #Rendered;
            key_val_data = [
              {
                key = "description";
                val = #TextContent("Videate Episode");
              },
              {
                key = "tag";
                val = #TextContent("episode");
              },
              {
                key = "contentType";
                val = #TextContent("text/plain");
              },
              {
                key = "locationType";
                val = #Nat8Content(4);
              },
            ];
            data = Text.encodeUtf8("https://rss.videate.org/" # episode.feedKey # "&episode=" # Nat.toText(episode.id));
          },
        ];

        let mintReceipt : MintReceipt = NftDb.mintDip721(
          nftDb,
          // Caller
          Principal.fromActor(Self),
          // Owner of newly minted NFT
          msg.caller,
          metadata,
        );

        switch (mintReceipt) {
          case (#ok(mintReceiptPart : MintReceiptPart)) {
            // Associate the Episode with the new tokenId
            let setNftTokenIdResult = credits.setNftTokenId(
              episode,
              mintReceiptPart.token_id,
            );
            switch (setNftTokenIdResult) {
              case (#ok()) {
                return #ok(#MintReceiptPart(mintReceiptPart));
              };
              case (#err(e : CreditsError)) {
                return #err(#CreditsError(e));
              };
            };
          };
          case (#err(e : NftError)) {
            return #err(#NftError(e));
          };
        };
      };
    };
  };

  /* Credits interface */

  public shared (msg) func putFeed(
    feed : Feed,
  ) : async PutFeedFullResult {
    if (not credits.isInitialized()) {
      Debug.print("Credits module is uninitialized. Please execute `dfx canister call serve initialize` after initial deploy.");
      return #err(#CreditsError(#Uninitialized("Credits module has not been initialized. See dfx output for details.")));
    };
    let putFeedResult = credits.putFeed(msg.caller, feed);

    switch (putFeedResult) {
      case (#ok(actionPerformed)) {
        // Update the profile so they can find the feed they created (if they
        // already own this feed [i.e. this was an update], this will move the
        // feed to the top of their list)
        //
        // Note that, for now, we use the owner specified in the feed, not the
        // caller. The two should always match, except in the case of the
        // cloner for which the caller is dfx which is why we go with the
        // feed's owner here.
        //
        // todo: Use the caller as the owner, not the owner specified in the
        // feed. Make sure this works with the cloner.
        let addOwnedFeedKeyResult = contributors.addOwnedFeedKey(
          feed.owner,
          feed.key,
        );
        //(msg.caller, key);
        switch (addOwnedFeedKeyResult) {
          case (#ok(profile : Profile)) {
            return #ok(actionPerformed);
          };
          case (#err(e : ContributorsError)) {
            return #err(#ContributorsError(e));
          };
        };
      };
      case (#err(e : CreditsError)) {
        return #err(#CreditsError(e));
      };
    };
  };

  public func deleteFeed(key : FeedKey) {
    let feed : ?Feed = credits.getFeed(key);

    switch (feed) {
      case (null) { /* do nothing */ };
      case (?feed) {
        let owner : Principal = feed.owner;

        // First delete the owned feedKey from the Contributor who owns it, if any
        let _ = contributors.removeOwnedFeedKey(owner, key);

        // Now delete the feed itself
        credits.deleteFeed(key);
      };
    };
  };

  public query func getAllFeedKeys() : async [Text] {
    credits.getAllFeedKeys();
  };

  public query func getAllFeeds() : async [(Text, Feed)] {
    credits.getAllFeeds();
  };

  public query func getAllEpisodes(feedKey : Text) : async [Episode] {
    credits.getAllEpisodes(feedKey);
  };

  public query func getFeed(key : Text) : async ?Feed {
    credits.getFeed(key);
  };

  public func getMedia(id : MediaID) : async ?Media {
    credits.getMedia(id);
  };

  public func getEpisode(key : FeedKey, id : EpisodeID) : async ?Episode {
    credits.getEpisode(key, id);
  };

  public func getEpisodes(key : FeedKey) : async ?[Episode] {
    credits.getEpisodes(key);
  };

  public func getFeedSummary(key : Text) : async (Text, Text) {
    credits.getFeedSummary(key);
  };

  public func getAllFeedSummaries() : async [(Text, Text)] {
    await credits.getAllFeedSummaries();
  };

  public func getFeedEpisodeDetails(key : Text) : async (Text, [(Text, Text)]) {
    credits.getFeedEpisodeDetails(key);
  };

  public func getAllFeedEpisodeDetails() : async [(Text, [(Text, Text)])] {
    await credits.getAllFeedEpisodeDetails();
  };

  public func addMedia(mediaData : MediaData) : async Result.Result<Media, CreditsError> {
    credits.addMedia(mediaData);
  };

  public func updateMedia(newMedia : Media) : async Result.Result<(), CreditsError> {
    credits.updateMedia(newMedia);
  };

  public func addEpisode(episodeData : EpisodeData) : async Result.Result<Episode, CreditsError> {
    credits.addEpisode(episodeData);
  };

  public func updateEpisode(episode : Episode) : async Result.Result<(), CreditsError> {
    credits.updateEpisode(episode);
  };

  // public query func getSampleFeed() : async Feed {
  //   credits.getSampleFeed();
  // };

  func getFeedXml(
    feed : Feed,
    episodeId : ?EpisodeID,
    requestorPrincipal : ?Text,
    frontendUri : Text,
    feedUri : Text,
    contributors : Contributors.Contributors,
    nftDb : NftDb.NftDb,
  ) : Text {
    let doc : Document = Rss.format(
      credits,
      feed,
      episodeId,
      requestorPrincipal,
      frontendUri,
      feedUri,
      contributors,
      nftDb,
    );
    Xml.stringifyDocument(doc);
  };

  func transformUri(input : Text, uriTransformers : [UriTransformer]) : Text {
    // Run all the transformers in order
    return Array.foldLeft(
      uriTransformers,
      input,
      func(previousValue : Text, transformer : UriTransformer) : Text = transformer(previousValue),
    );
  };

  /* Contributors interface */

  public func getContributorName(principal : Principal) : async ?Text {
    contributors.getName(principal);
  };
  public shared (msg) func addRequestedFeedKey(feedKey : Text) : async ProfileResult {
    contributors.addRequestedFeedKey(msg.caller, feedKey);
  };
  public shared (msg) func getOwnedFeedKeys(principal : Principal) : async [Text] {
    contributors.getOwnedFeedKeys(principal);
  };
  public shared (msg) func removeAllOwnedFeedKeys(principal : Principal) : async ProfileResult {
    contributors.removeAllOwnedFeedKeys(principal);
  };

  public shared (msg) func createContributor(profile : Contributors.ProfileUpdate) : async Result.Result<(), ContributorsError> {
    contributors.create(msg.caller, profile);
  };
  public shared (msg) func readContributor() : async Result.Result<Profile, ContributorsError> {
    contributors.read(msg.caller);
  };
  public shared (msg) func updateContributor(profile : ProfileUpdate) : async Result.Result<(), ContributorsError> {
    contributors.update(msg.caller, profile);
  };
  public shared (msg) func deleteContributor() : async Result.Result<(), ContributorsError> {
    contributors.delete(msg.caller);
  };

  /* nft interface */

  public query func balanceOfDip721(user : Principal) : async Nat64 {
    NftDb.balanceOfDip721(nftDb, user);
  };

  public query func ownerOfDip721(token_id : NftDb.TokenId) : async NftDb.OwnerResult {
    NftDb.ownerOfDip721(nftDb, token_id);
  };

  public shared ({ caller }) func safeTransferFromDip721(
    from : Principal,
    to : Principal,
    token_id : NftDb.TokenId,
  ) : async NftDb.TxReceipt {
    NftDb.safeTransferFromDip721(nftDb, caller, from, to, token_id);
  };

  public shared ({ caller }) func transferFromDip721(
    from : Principal,
    to : Principal,
    token_id : NftDb.TokenId,
  ) : async NftDb.TxReceipt {
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

  public query func getMetadataDip721(token_id : NftDb.TokenId) : async NftDb.MetadataResult {
    NftDb.getMetadataDip721(nftDb, token_id);
  };

  public query func getMaxLimitDip721() : async Nat16 {
    NftDb.getMaxLimitDip721(nftDb);
  };

  public func getMetadataForUserDip721(user : Principal) : async NftDb.ExtendedMetadataResult {
    NftDb.getMetadataForUserDip721(nftDb, user);
  };

  public query func getTokenIdsForUserDip721(user : Principal) : async [NftDb.TokenId] {
    NftDb.getTokenIdsForUserDip721(nftDb, user);
  };

  public shared ({ caller }) func mintDip721(
    to : Principal,
    metadata : NftDb.MetadataDesc,
  ) : async MintReceipt {
    NftDb.mintDip721(nftDb, caller, to, metadata);
  };

  public shared ({ caller }) func initialize() : async Result.Result<(), ServeError> {
    // Add the caller as the first custodian. This gives all rights to the
    // person who deployed this canister, as long as they make the first
    // initialize call. Note that this call will fail if the class already has
    // a custodian; this method can only be called on an uninitialized nftDb
    // object.
    switch (NftDb.addCustodian(nftDb, caller, caller)) {
      case (#ok()) {
        // continue
      };
      case (#err(e)) {
        return #err(#NftError(e));
      };
    };

    // Also add this canister as a custodian, without which this canister
    // wouldn't be able to mint or transfer NFTs
    switch (NftDb.addCustodian(nftDb, caller, Principal.fromActor(Self))) {
      case (#ok()) {
        // continue
      };
      case (#err(e)) {
        return #err(#NftError(e));
      };
    };

    // Also add this canister as a custodian for the credits database, which
    // will allow the caller (usually the dfx instance) to perform certain
    // operations like uploading feeds for users other than itself (this is
    // necessary so that cloning works since that requires dfx to be able to
    // manage anyone's feed).
    switch (credits.addCustodian(caller, caller)) {
      case (#ok()) {
        return #ok();
      };
      case (#err(e)) {
        return #err(#CreditsError(e));
      };
    };
  };
};
