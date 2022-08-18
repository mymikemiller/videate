import Xml "xml";
import Credits "../credits/credits";
import NftDb "../nft_db/nft_db";
import Contributors "../contributors/contributors";
import Types "../types";
import Array "mo:base/Array";
import List "mo:base/List";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Principal "mo:base/Principal";

module {
  type Document = Xml.Document;
  type Element = Xml.Element;
  type Feed = Credits.Feed;
  type Media = Credits.Media;
  type UriTransformer = Types.UriTransformer;

  // todo: this can be significantly cleaned up using default values. See
  // https://forum.dfinity.org/t/initializing-an-object-with-optional-nullable-fields/1790
  //
  // This rss format was based on the template here:
  // https://jackbarber.co.uk/blog/2017-02-14-podcast-rss-feed-template
  //
  // Validation can be perfomed here:
  // https://validator.w3.org/feed/#validate_by_input
	public func format(feed: Feed, key: Text, episodeGuid: ?Text, requestorPrincipal: ?Text, frontendUri: Text, contributors: Contributors.Contributors, nftDb: NftDb.NftDb, mediaUriTransformers: [UriTransformer]) : Document {
    // let Dip721NFT = actor("rno2w-sqaaa-aaaaa-aaacq-cai"): actor { ownerOfDip721: (token_id: Dip721NFTTypes.TokenId) -> async Dip721NFTTypes.OwnerResult };

    var mediaArray: [Media] = [];
    switch(episodeGuid) {
      case null {
        // Normal case. Caller did not specify an episode, so use all media
        mediaArray := feed.mediaList;
      };
      case (? guid) {
        // Caller specified an episode, so generate a Document containing only
        // that episode
        let episodeMedia = Array.find<Media>(feed.mediaList, func(media: Media): Bool {
          media.uri == guid; // Assume the guid is the media uri, though this may change
        });

        switch(episodeMedia) {
          case null {
            // Error. An episode guid was specified but we did not find that guid
            return {
              prolog = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
              root = {
                name = "Error";
                attributes = [];
                text = "Episode not found with guid: " # guid;
                children = [];
              }
            };
          };
          case (? media) {
            // Use an array containing only the single requested episode
            mediaArray := [media];
          };
        };
      };
    };
    let mediaList: List.List<Media> = List.fromArray<Media>(mediaArray);
    let mediaListNewestToOldest: List.List<Media> = List.reverse(mediaList);

    // todo: Limit the media list to the most recent 3 episodes unless there is
    // a registered user making the request 
    // let splitMediaList = List.split(3, mediaListNewestToOldest); 
    // let (shownMediaList, _) = splitMediaList;
    
		return {
			prolog = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
			root = {
				name = "rss";
				attributes = [ 
					("xmlns:itunes", "http://www.itunes.com/dtds/podcast-1.0.dtd"),
					("xmlns:content", "http://purl.org/rss/1.0/modules/content/"),
          ("xmlns:atom", "http://www.w3.org/2005/Atom"),
					("version", "2.0")
				];
        text = "";
				children = [
					{
						name = "channel";
            attributes = [];
            text = "";
						children = List.toArray(List.append(List.fromArray([
              {
                name = "atom:link";
                attributes = [
                  ("href", "http://videate.org/link-to-self.xml"), //todo: use correct link, probably with all the user-specific metadata
                  ("rel", "self"),
                  ("type", "application/rss+xml")
                ];
                text = "";
                children = [];
              }, {
								name = "title";
                attributes = [];
                text = feed.title;
                children = [];
              }, {
								name = "link";
                attributes = [];
                text = feed.link;
                children = [];
              }, {
								name = "language";
                attributes = [];
                text = "en-us";
                children = [];
              }, {
								name = "itunes:subtitle";
                attributes = [];
                text = feed.subtitle;
                children = [];
              }, {
								name = "itunes:author";
                attributes = [];
                text = feed.author;
                children = [];
              }, {
								name = "itunes:summary";
                attributes = [];
                text = feed.description;
                children = [];
              }, {
								name = "description";
                attributes = [];
                text = feed.description;
                children = [];
              }, {
								name = "itunes:owner";
                attributes = [];
                text = "";
                children = [
                  {
                    name = "itunes:name";
                    attributes = [];
                    text = feed.author;
                    children = [];
                  }, {
                    name = "itunes:email";
                    attributes = [];
                    text = feed.email;
                    children = [];
                  }
                ];
              }, {
								name = "itunes:explicit";
                attributes = [];
                text = "no"; // todo: use correct explicit
                children = [];
              },  {
								name = "itunes:image";
                attributes = [("href", feed.imageUrl)];
                text = "";
                children = [];
              }, {
								name = "itunes:category";
                attributes = [("text", "Arts")]; // todo: use correct category
                text = "";
                children = [];
              }]),
              List.map<Media, Element>(mediaListNewestToOldest, func(media: Media) : Element {
                getMediaElement(media, key, requestorPrincipal, frontendUri, contributors, nftDb, mediaUriTransformers);
              })
            ));
					},
				];
			};
		};
	};

  func getMediaElement(media: Media, feedKey: Text, requestorPrincipal: ?Text, frontendUri: Text, contributors: Contributors.Contributors, nftDb: NftDb.NftDb, mediaUriTransformers: [UriTransformer]) : Element {
    let videateSettingsUri = frontendUri # "?feedKey=" # feedKey;
    let nftPurchaseUri = frontendUri # "/nft?feedKey=" # feedKey # "&episodeGuid=" # media.uri;

    let videateSettingsMessage: Text = media.description # "\n\nManage your Videate settings:\n\n" # videateSettingsUri # "\n\n";

    let nftOwnerMessage = switch(media.nftTokenId) {
      case (null) {
        "The NFT for this episode is currently unclaimed! Click here to by the NFT: ";
      };
      case (? nftTokenId) {
        switch(NftDb.ownerOfDip721(nftDb, nftTokenId)) {
          case (#Err(e)) {
            "Error retrieving NFT owner. See NFT details here: ";
          };
          case (#Ok(nftOwnerPrincipal: Principal)) {
            let msg = if (Option.get(requestorPrincipal, "null") == Principal.toText(nftOwnerPrincipal)) {
              "You own the NFT for this episode! See details here: ";
            } else {
              let nftOwnerName = contributors.getName(nftOwnerPrincipal);
              switch(nftOwnerName) {
                case (null) {
                  "Error retrieving NFT owner name. See NFT details here: ";
                };
                case (? name) {
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

    let mediaDescription = videateSettingsMessage # nftDescription;

    let uri = transformUri(media.uri, mediaUriTransformers);
    let guid = media.uri; // for now, use the media uri as the guid since that should be unique among a feed.

    {
      name = "item";
      attributes = [];
      text = "";
      children = [
        {
          name = "title";
          attributes = [];
          text = media.title;
          children = [];
        }, {
          name = "itunes:summary";
          attributes = [];
          text = mediaDescription;
          children = [];
        }, {
          name = "description";
          attributes = [];
          text = mediaDescription;
          children = [];
        }, {
          name = "link";
          attributes = [];
          text = uri; // todo: this should link to a page describing the media, not the media itself
          children = [];
        }, {
          name = "enclosure";
          attributes = [
            ("url", uri), 
            ("type", "video/mpeg"), // todo: use correct media type
            ("length", "1024") // todo: use lengthInBytes
          ];
          text = "";
          children = [];
        }, {
          name = "pubDate";
          attributes = [];
          text = "21 Dec 2016 16:01:07 +0000"; // todo: use correct date
          children = [];
        }, {
          name = "itunes:author";
          attributes = [];
          text = "Mike Miller"; // todo: Use currect author name
          children = [];
        }, {
          name = "itunes:duration";
          attributes = [];
          text = "00:32:16"; // todo: Use correct duration
          children = [];
        }, {
          name = "itunes:explicit";
          attributes = [];
          text = "no"; // todo: use correct explicit
          children = [];
        }, {
          name = "guid";
          attributes = [];
          text = guid;
          children = [];
        }
      ];
    };
  };

  func transformUri(input: Text, uriTransformers: [UriTransformer]) : Text {
    // Run all the transformers in order
    return Array.foldLeft(uriTransformers, input, func (previousValue: Text, transformer: UriTransformer) : Text = transformer(previousValue) );
  };
};
