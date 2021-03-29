import Xml "xml";
import Credits "credits";
import Types "types";
import Array "mo:base/Array";
import List "mo:base/List";
import Debug "mo:base/Debug";

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
	public func format(feed: Feed, uriTransformers: [UriTransformer]) : Document {
    // Limit the media list to the most recent 3 episodes. Todo: Allow the
    // limit to be greater if there is a registered user making the request
    let mediaList = List.fromArray(feed.mediaList);
    let mediaListNewestToOldest = List.reverse(mediaList);
    let splitMediaList = List.split(3, mediaListNewestToOldest);
    let (shownMediaList, _) = splitMediaList;
    let shownMediaArray = List.toArray(shownMediaList);
    
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
						children = Array.append([
              {
                name = "atom:link";
                attributes = [
                  ("href", "http://videate.org/link-to-self.xml"), //todo: use correct link, probably with all the user-specific metadata
                  ("rel", "self"),
                  ("type", "application/rss+xml")
                ];
                text = "";
                children = [];
              },
							{
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
              }],
              
              // episode list
              Array.map(shownMediaArray, func(media: Media) : Element { 
                let uri = transformUri(media.uri, uriTransformers);
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
                      text = media.description;
                      children = [];
                    }, {
                      name = "description";
                      attributes = [];
                      text = media.description;
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
                      text = media.uri;
                      children = [];
                    }
                  ];
                }
              })
            );
					},
				];
			};
		};
	};

  func transformUri(input: Text, uriTransformers: [UriTransformer]) : Text {
    // Run all the transformers in order
    return Array.foldLeft(uriTransformers, input, func (previousValue: Text, transformer: UriTransformer) : Text = transformer(previousValue) );
  }
};
