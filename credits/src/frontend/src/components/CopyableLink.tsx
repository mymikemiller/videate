import { Actor, ActorSubclass } from "@dfinity/agent";
import React, { useCallback, useEffect, useRef, useState } from "react"; // import * as React from 'react'
import {
  Feed,
  _SERVICE as _SERVE_SERVICE,
} from "../../../declarations/serve/serve.did";
// import { canisterId as frontendCid } from "../../../declarations/frontend";
import { useContext } from "react";
import { AppContext } from "../App";
import toast from "react-hot-toast";
import { frontend } from "../../../declarations/frontend";

const isDevelopment = process.env.NODE_ENV !== "production";
const urlTemplate = isDevelopment ?
  '{origin}/{feedKey}?frontendCid={frontendCid}&principal={principal}'
  : 'https://{serveCid}.raw.ic0.app/{feedKey}?frontendCid={frontendCid}&principal={principal}';

interface CopyableLinkProps {
  serveActor: ActorSubclass<_SERVE_SERVICE>;
  feedKey: string;
};

const CopyableLink = ({ serveActor, feedKey }: CopyableLinkProps) => {
  const { authClient } = useContext(AppContext);
  const [exists, setExists] = useState(true);
  const [feed, setFeed] = useState<Feed | undefined>(undefined);
  const [customizedFeedUrl, setCustomizedFeedUrl] = useState<string>("");
  const mountedRef = useRef(true);


  const setup = useCallback(async () => {
    try {
      if (!authClient) {
        return;
      };

      if (!serveActor) {
        return;
      };

      const feeds: [Feed] | [] = await serveActor.getFeed(feedKey);
      var feed: Feed | undefined = undefined;

      // Note that we cannot use optional chaining here (feeds?.at(0)) as it is
      // not supported in Apple Podcast's internal browser
      if (feeds?.length == 1) feed = feeds[0];

      // Don't allow the setState calls below if this component is unmounted
      if (!mountedRef.current) return null;

      if (!feed) {
        console.error(`Feed ${feedKey} does not exist.`);
        setExists(false);
        return;
      }

      setFeedInfo(feed);
    } catch (error) {
      console.error(error);
    }
  }, [mountedRef]);

  const setFeedInfo = (feed: Feed) => {
    const serveCid = Actor.canisterIdOf(serveActor).toText();

    // The url needs to point to the serve canister, but we want to keep the
    // other details of the host in tact (i.e. let the latter half of the host
    // stay as either .localhost or .ic0.app). So we want
    // window.location.origin, but we switch out the cid to point to serve.
    const frontendCid = window.location.origin.split('//')[1].split('.')[0];
    console.log("got frontend Cid: ", frontendCid);
    const origin = window.location.origin.replace(frontendCid, serveCid)
    const url = urlTemplate
      .replace('{origin}', origin)
      .replace('{feedKey}', feedKey)
      .replace('{serveCid}', serveCid)
      .replace('{frontendCid}', frontendCid)
      .replace('{principal}', authClient!.getIdentity().getPrincipal().toText());

    setExists(true);
    setFeed(feed);
    setCustomizedFeedUrl(url);
  };

  // This pattern is from https://stackoverflow.com/a/63371024/1160216 and
  // avoids leaving unfinished async calls around resulting in React warnings.
  useEffect(() => {
    setup();
    return () => {
      mountedRef.current = false; // clean up
    };
  }, [setup]);

  function copy() {
    navigator.clipboard.writeText(customizedFeedUrl)
      .then(() => {
        toast.success('Copied!');
      })
      .catch(err => {
        toast.error('Error copying URL. Try selecting the text and copying manually.');
      })
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
