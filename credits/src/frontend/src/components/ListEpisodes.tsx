// List all Episodes for a given Feed, including a link to edit individual
// Episodes
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
  Episode,
  _SERVICE,
  EpisodeID,
} from "../../../declarations/serve/serve.did";
import Loop from "../../assets/loop.svg";
import { useForm } from "react-hook-form";
import { AppContext } from "../App";
import toast from "react-hot-toast";
import { Button, Icon } from "@adobe/react-spectrum";
import { Section, FormContainer, Title, Label, Input, GrowableInput, LargeButton, LargeBorder, LargeBorderWrap, ValidationError } from "./styles/styles";

// If feed is not provided when navigating to the ListEpiosode page, the feed at
// the 'feedKey' search param will be fetched.
interface ListEpisodeProps {
  feed?: Feed;
};

const ListEpisodes = (): JSX.Element => {
  const { actor, authClient, login, profile } = useContext(AppContext);
  const { state } = useLocation();
  const [searchParams] = useSearchParams();
  const [feedKey, setFeedKey] = useState(searchParams.get('feed'));
  const navigate = useNavigate();

  const [feed, setFeed] = useState<Feed>();
  const [episodes, setEpisodes] = useState<Episode[]>();

  useEffect(() => {
    if (state) {
      const { feed: incomingFeed } = state as ListEpisodeProps;
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

  useEffect(() => {
    if (feed) {
      (async () => {
        let episodesResult = await actor!.getEpisodes(feed.key);
        if (episodesResult.length == 1) {
          setEpisodes(episodesResult[0]);
        } else {
          setEpisodes([]);
        }
      })();
    }
  }, [feed]);

  // todo: break this out into a reusable component
  if (authClient == null || actor == null) {
    return (
      <Section>
        <h3>Please authenticate before editing Episodes</h3>
        <Button variant="cta" onPress={login}>
          Login with&nbsp;
          <Icon>
            <Loop />
          </Icon>
        </Button>
      </Section>
    );
  };

  const putEpisode = async () => {
    navigate('/putEpisode/?feed=' + feedKey, { state: { feed } });
  };

  if (!feedKey) {
    return <h1>feedKey must be specified as a search param so we know which feed's Episode to list.</h1>
  };

  if (!feed) return <h1>Loading feed...</h1>;

  if (episodes == null) return <h1>"Loading episodes..."</h1>;

  return (
    <>
      <Title>{"Episodes for \"" + feedKey + "\" Feed"}</Title>
      {episodes.length == 0 && "No episodes yet. Add an episode by clicking below:"}
      {episodes.map((episode: Episode) =>
        <div key={Number(episode.id)}>
          {episode.title}&nbsp;&nbsp;
          <Link to={'/putEpisode?feed=' + feedKey} state={{ feedKey, feed, episode }}>
            Edit
          </Link>
        </div>)
      }
      <br></br>
      &nbsp;
      <ButtonGroup>
        <ActionButton onPress={putEpisode}>
          <AddCircle />
          <Text>Add Episode</Text>
        </ActionButton>
      </ButtonGroup>
    </>
  );
};

export default ListEpisodes;
