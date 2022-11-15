import Buffer "mo:base/Buffer";
import Xml "xml";
import Credits "../credits/credits";
import NftDb "../nft_db/nft_db";
import Contributors "../contributors/contributors";
import Types "../types";
import Utils "../utils";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

module {
  type Document = Xml.Document;
  type Element = Xml.Element;
  type Feed = Credits.Feed;
  type MediaID = Credits.MediaID;
  type EpisodeID = Credits.EpisodeID;
  type Media = Credits.Media;
  type Episode = Credits.Episode;

  // todo: this can be significantly cleaned up using default values. See
  // https://forum.dfinity.org/t/initializing-an-object-with-optional-nullable-fields/1790
  //
  // This rss format was based on the template here:
  // https://jackbarber.co.uk/blog/2017-02-14-podcast-rss-feed-template
  //
  // Validation can be perfomed here:
  // https://validator.w3.org/feed/#validate_by_input
  public func format(
    credits : Credits.Credits,
    feed : Feed,
    episodeId : ?EpisodeID,
    requestorPrincipal : ?Text,
    frontendUri : Text,
    feedUri : Text,
    contributors : Contributors.Contributors,
    nftDb : NftDb.NftDb,
  ) : Document {
    let episodeIds : [EpisodeID] = switch (episodeId) {
      case null {
        // Normal case. Caller did not specify an Episode, so use all Episodes
        feed.episodeIds;
      };
      case (?episodeId) {
        // Use only the single Episode specified by the caller
        [episodeId];
      };
    };

    // Use mapResult to return early with an error when an Episode isn't found
    let episodesResult = Array.mapResult<EpisodeID, Episode, Text>(
      episodeIds,
      func(id : EpisodeID) : Result.Result<Episode, Text> {
        switch (credits.getEpisode(feed.key, id)) {
          case (null) #err("Episode with ID " # Nat.toText(id) # " not found in " # feed.key # " feed");
          case (?episode) #ok(episode);
        };
      },
    );

    let episodes = switch (episodesResult) {
      case (#ok(episodes)) {
        // All Episodes were found
        episodes;
      };
      case (#err(msg : Text)) {
        // There was an Episode not found. Notify the user.
        return {
          prolog = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
          root = {
            name = "Error";
            attributes = [];
            text = msg;
            children = [];
          };
        };
      };
    };

    let episodeList : List.List<Episode> = List.fromArray<Episode>(episodes);
    let episodeListNewestToOldest : List.List<Episode> = List.reverse(episodeList);

    // todo: Limit the episodes list to the most recent 3 episodes unless there
    // is a registered user making the request
    // let splitEpisodeList = List.split(3, episodeistNewestToOldest);
    // let (shownEpisodeList, _) = splitEpisodeList;

    return {
      prolog = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
      root = {
        name = "rss";
        attributes = [
          ("xmlns:itunes", "http://www.itunes.com/dtds/podcast-1.0.dtd"),
          ("xmlns:content", "http://purl.org/rss/1.0/modules/content/"),
          ("xmlns:atom", "http://www.w3.org/2005/Atom"),
          ("version", "2.0"),
        ];
        text = "";
        children = [
          {
            name = "channel";
            attributes = [];
            text = "";
            children = List.toArray(
              List.append(
                List.fromArray(
                  [
                    {
                      name = "atom:link";
                      attributes = [
                        //todo: use correct link, probably with all the user-specific metadata
                        ("href", "http://videate.org/link-to-self.xml"),
                        ("rel", "self"),
                        ("type", "application/rss+xml"),
                      ];
                      text = "";
                      children = [];
                    },
                    {
                      name = "title";
                      attributes = [];
                      text = feed.title;
                      children = [];
                    },
                    {
                      name = "link";
                      attributes = [];
                      text = feed.link;
                      children = [];
                    },
                    {
                      name = "language";
                      attributes = [];
                      text = "en-us";
                      children = [];
                    },
                    {
                      name = "itunes:subtitle";
                      attributes = [];
                      text = feed.subtitle;
                      children = [];
                    },
                    {
                      name = "itunes:author";
                      attributes = [];
                      text = feed.author;
                      children = [];
                    },
                    {
                      name = "itunes:summary";
                      attributes = [];
                      text = feed.description;
                      children = [];
                    },
                    {
                      name = "description";
                      attributes = [];
                      text = feed.description;
                      children = [];
                    },
                    {
                      name = "itunes:owner";
                      attributes = [];
                      text = "";
                      children = [
                        {
                          name = "itunes:name";
                          attributes = [];
                          text = feed.author;
                          children = [];
                        },
                        {
                          name = "itunes:email";
                          attributes = [];
                          text = feed.email;
                          children = [];
                        },
                      ];
                    },
                    {
                      name = "itunes:explicit";
                      attributes = [];
                      //todo: use correct explicit
                      text = "no";
                      children = [];
                    },
                    {
                      name = "itunes:image";
                      attributes = [("href", feed.imageUrl)];
                      text = "";
                      children = [];
                    },
                    {
                      name = "itunes:category";
                      // todo: use correct category
                      attributes = [("text", "Arts")];
                      text = "";
                      children = [];
                    },
                  ],
                ),
                List.map<Episode, Element>(
                  episodeListNewestToOldest,
                  func(episode : Episode) : Element {
                    getEpisodeElement(
                      credits,
                      episode,
                      requestorPrincipal,
                      frontendUri,
                      feedUri,
                      contributors,
                      nftDb,
                    );
                  },
                ),
              ),
            );
          },
        ];
      };
    };
  };

  func getEpisodeElement(
    credits : Credits.Credits,
    episode : Episode,
    requestorPrincipal : ?Text,
    frontendUri : Text,
    feedUri : Text,
    contributors : Contributors.Contributors,
    nftDb : NftDb.NftDb,
  ) : Element {
    let videateSettingsUri = frontendUri # "?feed=" # episode.feedKey;
    let nftPurchaseUri = frontendUri # "/nft?feed=" # episode.feedKey # "&episode=" # debug_show (episode.id);

    let videateSettingsMessage : Text = episode.description # "\n\nManage your Videate settings:\n\n" # videateSettingsUri # "\n\n";

    let nftOwnerMessage = switch (episode.nftTokenId) {
      case (null) {
        "The NFT for this episode is currently unclaimed! Click here to buy the NFT: ";
      };
      case (?nftTokenId) {
        switch (NftDb.ownerOfDip721(nftDb, nftTokenId)) {
          case (#err(e)) {
            "Error retrieving NFT owner. See NFT details here: ";
          };
          case (#ok(nftOwnerPrincipal : Principal)) {
            let msg = if (Option.get(requestorPrincipal, "null") == Principal.toText(nftOwnerPrincipal)) {
              "You own the NFT for this episode! See details here: ";
            } else {
              let nftOwnerName = contributors.getName(nftOwnerPrincipal);
              switch (nftOwnerName) {
                case (null) {
                  "Error retrieving NFT owner name. See NFT details here: ";
                };
                case (?name) {
                  name # " owns the NFT for this video. Click here to buy it: ";
                };
              };
            };
            msg;
          };
        };
      };
    };
    let nftDescription = nftOwnerMessage # "\n\n" # nftPurchaseUri;

    let episodeDescription = videateSettingsMessage # nftDescription;

    let media : Media = switch (credits.getMedia(episode.mediaId)) {
      case (null) {
        // Media for this Episode was not found. Notify the user.
        return {
          name = "Error";
          attributes = [];
          text = "Media not found for Episode " # Nat.toText(episode.id) # " in feed " # episode.feedKey # ". Expected to find MediaID " # Nat.toText(episode.mediaId) # ".";
          children = [];
        };
      };
      case (?media) {
        media;
      };
    };

    // If the feedUri already includes a query param (likely for the
    // canisterId), we use "&" to add additional, otherwise we use "?" to add
    // the first
    let queryParamStart = if (Text.contains(feedUri, #text("?"))) { "&" } else {
      "?";
    };

    let episodeUri = feedUri # queryParamStart # "episode=" # Nat.toText(episode.id);
    let mediaUri = episodeUri # "&media=true";

    // Episode ID is unique per Episode in the Feed and can be used as the guid
    let guid = Nat.toText(episode.id);

    {
      name = "item";
      attributes = [];
      text = "";
      children = [
        {
          name = "title";
          attributes = [];
          text = episode.title;
          children = [];
        },
        {
          name = "itunes:summary";
          attributes = [];
          text = episodeDescription;
          children = [];
        },
        {
          name = "description";
          attributes = [];
          text = episodeDescription;
          children = [];
        },
        {
          name = "link";
          attributes = [];
          text = episodeUri;
          children = [];
        },
        {
          name = "enclosure";
          attributes = [
            ("url", mediaUri),
            // todo: use correct media type
            ("type", "video/mpeg"),
            // todo: use lengthInBytes
            ("length", "1024"),
          ];
          text = "";
          children = [];
        },
        {
          name = "pubDate";
          attributes = [];
          // todo: use correct date
          text = "21 Dec 2016 16:01:07 +0000";
          children = [];
        },
        {
          name = "itunes:author";
          attributes = [];
          // todo: Use currect author name
          text = "Mike Miller";
          children = [];
        },
        {
          name = "itunes:duration";
          attributes = [];
          // todo: Use correct duration
          text = "00:32:16";
          children = [];
        },
        {
          name = "itunes:explicit";
          attributes = [];
          // todo: use correct explicit
          text = "no";
          children = [];
        },
        {
          name = "guid";
          attributes = [("isPermaLink", "false")];
          text = guid;
          children = [];
        },
      ];
    };
  };
};
