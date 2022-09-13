// List all media for a given feed, including a link to edit individual Media
import {
  ActionButton,
  ButtonGroup,
  Text,
} from "@adobe/react-spectrum";
import AddCircle from "@spectrum-icons/workflow/AddCircle";
import React, {
  useContext, useEffect, useState,
} from "react";
import {
  useNavigate,
  Link,
} from "react-router-dom";
import { useSearchParams, useLocation } from 'react-router-dom';
import {
  Feed,
  Media,
  _SERVICE,
} from "../../../declarations/serve/serve.did";
import Loop from "../../assets/loop.svg";
import { useForm } from "react-hook-form";
import { AppContext } from "../App";
import toast from "react-hot-toast";
import { Button, Icon } from "@adobe/react-spectrum";
import { Section, FormContainer, Title, Label, Input, GrowableInput, LargeButton, LargeBorder, LargeBorderWrap, ValidationError } from "./styles/styles";

// If feed is not provided when navigating to the ListMedia page, the feed at
// the 'feedKey' search param will be fetched.
interface ListMediaProps {
  feed?: Feed;
};

const ListMedia = (): JSX.Element => {
  const { actor, authClient, login, profile } = useContext(AppContext);
  const { state } = useLocation();
  const [searchParams] = useSearchParams();
  const [feedKey, setFeedKey] = useState(searchParams.get('feedKey'));
  const navigate = useNavigate();

  const [feed, setFeed] = useState<Feed>();

  useEffect(() => {
    if (state) {
      const { feed: incomingFeed } = state as ListMediaProps;
      setFeed(incomingFeed);
    }
  }, []);

  useEffect(() => {
    // If we weren't initialized with a feed, fetch the one at feedKey
    if (!feed) {
      if (actor && feedKey && profile?.ownedFeedKeys.includes(feedKey)) {
        (async () => {
          const feed = await actor.getFeed(feedKey!);
          // If we got a feed back, set it. Note that feed.length does not
          // refer to the number of episodes in the feed. It refers to whether
          // the array came back empty or containing a feed.
          if (feed.length == 1) {
            setFeed(feed[0]);
          }
        })();
      }
    }
  }, [feedKey, actor, profile]);

  // todo: break this out into a reusable component
  if (authClient == null || actor == null) {
    return (
      <Section>
        <h3>Please authenticate before editing Media</h3>
        <Button variant="cta" onPress={login}>
          Login with&nbsp;
          <Icon>
            <Loop />
          </Icon>
        </Button>
      </Section>
    );
  };

  const putMedia = async () => {
    navigate('/putMedia/?feedKey=' + feedKey, { state: { feed } });
  };

  if (!feedKey) {
    return <h1>feedKey must be specified as a search param so we know which feed's media to list.</h1>
  };

  if (!feed) {
    return <h1>Loading feed...</h1>
  };

  // todo: don't assume media.uri is unique when setting key (use generated
  // episodeGuid)
  return (
    <>
      <Title>{"Media for \"" + feedKey + "\" Feed"}</Title>
      {feed.mediaList.length == 0 && "No media yet. Add an episode by clicking below:"}
      {feed.mediaList.map((media: Media) =>
        <div key={media.uri}>
          {media.title}&nbsp;&nbsp;
          <Link to={'/putMedia?feedKey=' + feedKey} state={{ feedKey, feed, media }}>
            Edit
          </Link>
        </div>)
      }
      <br></br>
      &nbsp;
      <ButtonGroup>
        <ActionButton onPress={putMedia}>
          <AddCircle />
          <Text>Add Media</Text>
        </ActionButton>
      </ButtonGroup>
    </>
  );
};

export default ListMedia;
