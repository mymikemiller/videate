// Manage the feeds owned by the current user (e.g. create new feeds or upload media)
import {
  ActionButton,
  ButtonGroup,
  Heading,
  Text,
} from "@adobe/react-spectrum";
import React, { useEffect, useState } from "react";
import { useContext } from "react";
import { useNavigate } from "react-router-dom";
import {
  _SERVICE,
} from "../../../declarations/serve/serve.did";
import { AppContext } from "../App";
import FeedLink, { Mode as FeedLinkMode } from "./FeedLink";
import { _SERVICE as _SERVE_SERVICE } from "../../../declarations/serve/serve.did";
import FeedAdd from "@spectrum-icons/workflow/FeedAdd";

function ManageFeeds() {
  const { actor, profile, setProfile } = useContext(AppContext);
  const navigate = useNavigate();

  const createFeed = async () => {
    navigate("/createFeed");
  };

  if (!profile) {
    return null;
  }

  return (
    <>
      {profile.ownedFeedKeys.length == 0 && <p>You don't own any feeds. Create a feed first.</p>}
      {profile.ownedFeedKeys.length > 0 && <>
        <Heading level={2}>
          Here are the feeds you manage:
        </Heading><br /><br />
        <ul style={{ padding: 0 }} >
          {profile.ownedFeedKeys.map((feedKey, index) => {
            return (
              <li key={feedKey} style={{ listStyleType: 'none', marginBottom: '1em' }} >
                <FeedLink mode={FeedLinkMode.Edit} feedKey={feedKey} />
              </li>
            )
          })}
        </ul>
      </>
      }

      <ButtonGroup>
        <ActionButton onPress={createFeed}>
          <FeedAdd />
          <Text>Create New Feed</Text>
        </ActionButton>
      </ButtonGroup>
    </>
  );
}

export default ManageFeeds;
