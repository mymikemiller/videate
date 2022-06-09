import { Actor, ActorSubclass } from "@dfinity/agent";
import React, { useEffect, useState } from "react"; // import * as React from 'react'
import {
  Feed,
  _SERVICE as _SERVE_SERVICE,
} from "../../../declarations/serve/serve.did";
import { canisterId as assetsCanisterId } from "../../../declarations/contributor_assets";
import { useContext } from "react";
import { AppContext } from "../App";
import toast from "react-hot-toast";

const isDevelopment = process.env.NODE_ENV !== "production";
const urlTemplate = isDevelopment ?
  '{origin}/{feedKey}?canisterId={serveCanisterId}&contributorAssetsCid={contributorAssetsCid}&principal={principal}'
  : 'https://{serveCanisterId}.raw.ic0.app/{feedKey}?contributorAssetsCid={contributorAssetsCid}&principal={principal}';

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

    if (!serveActor) {
      return;
    }

    const feeds: [Feed] | [] = await serveActor.getFeed(feedKey);
    var feed: Feed | undefined = undefined;
    // Note that we cannot use optional chaining here (feeds?.at(0)) as it is
    // not supported in Apple Podcast's internal browser
    if (feeds?.length == 1) feed = feeds[0];

    if (!feed) {
      console.error(`Feed ${feedKey} does not exist.`);
      setExists(false);
      return;
    } else {
      const url = urlTemplate
        .replace('{origin}', window.location.origin)
        .replace('{feedKey}', feedKey)
        .replace('{serveCanisterId}', Actor.canisterIdOf(serveActor).toText())
        .replace('{contributorAssetsCid}', assetsCanisterId!)
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
      <div style={{ display: 'flex', flexDirection: 'column', flexGrow: 1 }}> {/* name and stuff below */}
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
