import Xml "xml";
import Credits "canister:credits";

module {
  type Document = Xml.Document;

	public func getFeed() : async Document {
		var media = await Credits.getAllMedia();
		{
			prolog = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
			//<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
			root = #element {
				name = "rss";
				attributes = [ 
					("xmlns:itunes", "http://www.itunes.com/dtds/podcast-1.0.dtd"),
					("xmlns:content", "http://purl.org/rss/1.0/modules/content/"),
					("version", "2.0")
				];
				children = [
					#element {
						name = "channel";
						attributes = [];
						children = [
							#element {
								name = "title";
								attributes = [];
								children = [ #text("TEST TITLE") ];
							},
						];
					},
				];
			};
		};
	};
};
