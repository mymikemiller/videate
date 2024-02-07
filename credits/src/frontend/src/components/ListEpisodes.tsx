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
import { Console } from "console";

// If feed is not provided when navigating to the ListEpisode page, the feed at
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
      if (actor && feedKey && profile?.ownedFeedKeys.includes(feedKey.toLowerCase())) {
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

  const moveEpisode = async (episode: Episode, amount: number) => {
    if (feed == null) {
      console.error("Cannot reorder episodes, feed is null");
      return;
    }

    const currentIndex = feed.episodeIds.findIndex(id => id === episode.id);
    if (currentIndex !== -1) {
      const newIndex = currentIndex + amount;
      if (newIndex >= 0 && newIndex < feed.episodeIds.length) {
        const updatedEpisodeIds = [...feed.episodeIds];
        const [movedEpisode] = updatedEpisodeIds.splice(currentIndex, 1);
        updatedEpisodeIds.splice(newIndex, 0, movedEpisode);
        // Update feed with new episode order
        const updatedFeed = { ...feed, episodeIds: updatedEpisodeIds };

        let putFeedResult = await actor!.putFeed(feed);
        if ("ok" in putFeedResult) {
          setFeed(updatedFeed);
        } else if ("err" in putFeedResult) {
          console.error(putFeedResult.err);
          toast.error(`${putFeedResult.err}`);
        };
      }
    }
  }

  if (!feedKey) {
    return <h1>feed must be specified as a search param so we know which feed's episodes to list.</h1>
  };

  if (!feed) return <h1>Loading feed...</h1>;

  if (episodes == null) return <h1>Loading episodes...</h1>;

  return (
    <>
      <Title>{"Episodes for \"" + feedKey + "\" Feed"}</Title>
      {episodes.length == 0 && "No episodes yet. Add an episode by clicking below:"}
      {episodes.map((episode: Episode, index: number) => 
      {
        const style: React.CSSProperties = { opacity: episode.hidden ? 0.5 : 1.0 };
        return (
          <div key={Number(episode.id)}>
            <button disabled={index == 0} onClick={() => moveEpisode(episode, -1)}>↑</button>
            <button disabled={index == episodes.length - 1} onClick={() => moveEpisode(episode, 1)}>↓</button>
            &nbsp;
            <Link to={'/putEpisode?feed=' + feedKey} state={{ feedKey, feed, episode }}>
              <button>Edit</button>
            </Link>
            &nbsp;&nbsp;
            <span style={style}>{episode.title}</span>

          </div >
        )
      })
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
