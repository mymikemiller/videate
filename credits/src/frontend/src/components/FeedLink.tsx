import { Actor } from "@dfinity/agent";
import React, { useCallback, useEffect, useRef, useState } from "react"; // import * as React from 'react'
import {
  Feed,
  _SERVICE as _SERVE_SERVICE,
} from "../../../declarations/serve/serve.did";
import { useContext } from "react";
import { AppContext } from "../App";
import toast from "react-hot-toast";
import { frontend } from "../../../declarations/frontend";
import { useNavigate } from "react-router-dom";

const isDevelopment = process.env.NODE_ENV !== "production";
const urlTemplate = isDevelopment ?
  '{origin}/{feedKey}?frontendCid={frontendCid}&principal={principal}'
  : 'https://{serveCid}.raw.ic0.app/{feedKey}?frontendCid={frontendCid}&principal={principal}';

export enum Mode {
  Copy, // Provides UI to copy the Feed URL for feeds the user subscribes to
  Edit, // Provides UI to edit the contents of a feed (e.g. add media)
};

interface FeedLinkProps {
  feedKey: string;
  mode: Mode;
};

const FeedLink = ({ feedKey, mode }: FeedLinkProps) => {
  const { actor, authClient } = useContext(AppContext);
  const [exists, setExists] = useState(true);
  const [feed, setFeed] = useState<Feed | undefined>(undefined);
  const [customizedFeedUrl, setCustomizedFeedUrl] = useState<string>("");
  const mountedRef = useRef(true);
  const navigate = useNavigate();

  const setup = useCallback(async () => {
    try {
      if (!authClient) {
        return;
      };

      if (!actor) {
        return;
      };

      const feeds: [Feed] | [] = await actor.getFeed(feedKey);
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
    const serveCid = Actor.canisterIdOf(actor!).toText();

    // The url needs to point to the serve canister, but we want to keep the
    // other details of the host in tact (i.e. let the latter half of the host
    // stay as either .localhost or .ic0.app). So we want
    // window.location.origin, but we switch out the cid to point to serve.
    const frontendCid = window.location.origin.split('//')[1].split('.')[0];
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

  // This mountedRef pattern is from
  // https://stackoverflow.com/a/63371024/1160216 and avoids leaving unfinished
  // async calls around resulting in React warnings.
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

  function editFeed() {
    navigate('/putFeed?feedKey=' + feedKey, { state: { key: feedKey, feed } });
  };
  function listMedia() {
    navigate('/listMedia?feedKey=' + feedKey, { state: { key: feedKey, feed } });
  };
  function putMedia() {
    navigate('/putMedia?feedKey=' + feedKey, { state: { feedKey, feed } });
  };

  if (!exists) {
    return null;
  };

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
        {mode == Mode.Copy &&
          <div style={{ display: 'flex', flexDirection: 'row', height: '30px', flexGrow: 1 }}> {/* url and copy button */}
            <input type="text" readOnly value={customizedFeedUrl} style={{ height: '100%', padding: 0, border: 0, paddingLeft: '1em', flexGrow: 1 }}></input>
            <button type="button" style={{ height: '100%' }} onClick={() => copy()}>Copy</button>
          </div>
        }
        {mode == Mode.Edit &&
          <div style={{ display: 'flex', flexDirection: 'row', height: '30px', flexGrow: 1 }}> {/* Add media button */}
            <button type="button" style={{ height: '100%' }} onClick={() => editFeed()}>Edit Feed</button>
            <button type="button" style={{ height: '100%' }} onClick={() => listMedia()}>Edit Media</button>
            <button type="button" style={{ height: '100%' }} onClick={() => putMedia()}>Add Media</button>
          </div>
        }
      </div>
    </div>
  );
}

export default FeedLink;
