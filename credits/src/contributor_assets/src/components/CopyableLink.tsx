import { ActorSubclass } from "@dfinity/agent";
import React, { useEffect, useState } from "react";
import {
  serve,
} from "../../../declarations/serve";
import {
  Feed,
  _SERVICE,
} from "../../../declarations/serve/serve.did";

interface CopyableLinkProps {
  serveActor: ActorSubclass<_SERVICE>;
  feedKey: string;
};


const CopyableLink = ({ serveActor, feedKey }: CopyableLinkProps) => {

  function copy() {
    alert('You clicked me!');
  };

  const [exists, setExists] = useState(true);
  const [feed, setFeed] = useState<Feed | undefined>(undefined);

  useEffect(() => {
    setFeedInfo(feedKey);
  }, []);

  const setFeedInfo = async (feedKey: string) => {
    console.log("CopyableLink is looking for key: " + feedKey);

    if (serve == undefined) {
      console.log('serve is undefined');
    };
    const feeds: [Feed] | [] = await serveActor.getFeed(feedKey);
    if (feeds.length == 0) {
      console.log('feeds is []');
    };
    const feed: Feed | undefined = feeds!.at(0);
    if (feed == undefined) {
      console.log('feed is undefined');
    };
    if (feed == undefined) {
      console.log('setting exists to false');
      setExists(false);
      return;
    } else {
      console.log('setting exists to true, and feed to ' + feed.title);
      setExists(true);
      setFeed(feed);
    };
  };

  if (!exists) {
    return null;
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'row', width: '100%', backgroundColor: '#1a1a1a' }}>
      <img style={{ width: 75, height: 75 }} src={feed?.imageUrl} />
      <div style={{ display: 'flex', flexDirection: 'column' }}> {/* name and stuff below */}
        <h5 style={{
          margin: '0.5em 1em',
          textOverflow: 'ellipsis',
          whiteSpace: 'nowrap',
          overflow: 'hidden',
          maxWidth: '50vw',
        }}>
          {feed?.title}
        </h5>
        <div style={{ display: 'flex', flexDirection: 'row', height: '30px', flexGrow: 1 }}> {/* url and copy button */}
          <input type="text" readOnly value={feed?.link} style={{ height: '100%', padding: 0, border: 0, paddingLeft: '1em', flexGrow: 1 }}></input>
          <button type="button" style={{ height: '100%' }} onClick={() => copy()}>Copy</button>
        </div>
      </div>
    </div>
  );
}

export default CopyableLink;
