import { ActorSubclass } from "@dfinity/agent";
import React, { useEffect, useState } from "react";
import {
  serve,
} from "../../../declarations/serve";
import {
  Feed,
  _SERVICE as _SERVE_SERVICE,
} from "../../../declarations/serve/serve.did";
import { useContext } from "react";
import { AppContext } from "../App";
import { Actor } from "@dfinity/agent";
import toast from "react-hot-toast";

const urlTemplate = 'localhost:8000/{feedKey}?canisterId={serveCanisterId}&principal={principal}';

interface CopyableLinkProps {
  serveActor: ActorSubclass<_SERVE_SERVICE>;
  feedKey: string;
};

const CopyableLink = ({ serveActor, feedKey }: CopyableLinkProps) => {

  const { authClient } = useContext(AppContext);
  const [exists, setExists] = useState(true);
  const [feed, setFeed] = useState<Feed | undefined>(undefined);
  const [customizedFeedUrl, setCustomizedFeedUrl] = useState<string>("");

  useEffect(() => {
    setFeedInfo(feedKey);
  }, []);

  function copy() {
    navigator.clipboard.writeText(customizedFeedUrl)
      .then(() => {
        toast.success('Copied!');
      })
      .catch(err => {
        toast.error('Error copying URL. Try selecting the text and copying manually.');
        console.error(err);
      })
  };

  const setFeedInfo = async (feedKey: string) => {
    if (!authClient) {
      console.error('null authClient when trying to set CopyableLink feed info');
      return;
    }

    const feeds: [Feed] | [] = await serveActor.getFeed(feedKey);
    const feed: Feed | undefined = feeds?.at(0);
    if (feed == undefined) {
      console.error(`Feed ${feedKey} does not exist.`);
      setExists(false);
      return;
    } else {
      const url = urlTemplate
        .replace('{feedKey}', feedKey)
        .replace('{serveCanisterId}', Actor.canisterIdOf(serveActor).toText())
        .replace('{principal}', authClient.getIdentity().getPrincipal().toText());

      setExists(true);
      setFeed(feed);
      setCustomizedFeedUrl(url);
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
          <input type="text" readOnly value={customizedFeedUrl} style={{ height: '100%', padding: 0, border: 0, paddingLeft: '1em', flexGrow: 1 }}></input>
          <button type="button" style={{ height: '100%' }} onClick={() => copy()}>Copy</button>
        </div>
      </div>
    </div>
  );
}

export default CopyableLink;
