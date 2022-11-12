import React, { useContext, useState, useEffect } from "react";
import { useSearchParams, useLocation, useNavigate } from 'react-router-dom';
import {
  _SERVICE,
  Episode,
  EpisodeData,
  Feed,
  Media,
  MediaData,
} from "../../../declarations/serve/serve.did";
import Loop from "../../assets/loop.svg";
import { useForm } from "react-hook-form";
import { AppContext } from "../App";
import toast from "react-hot-toast";
import { Button, ActionButton, Icon } from "@adobe/react-spectrum";
import { Section, FormContainer, Title, Label, Input, GrowableInput, LargeButton, LargeBorder, LargeBorderWrap, ValidationError } from "./styles/styles";
import DataAdd from "@spectrum-icons/workflow/DataAdd";

// We'll use dummy information for some fields for now, so we just ask for the
// ones we support right now
type Submission = {
  feed: Feed;
  title: string;
  description: string;
  uri: string;
}

interface PutEpisodeFormProps {
  // If feed is specified, we'll be able to copy over values from the most
  // recent Episode
  feed?: Feed;
  // If episode is specified, we're editing that Episode. The form will be
  // pre-popuated with that Episode's information, and that Episode will be
  // updated when submitting
  episode?: Episode;
};

// Specify defaultValues to pre-fill the form with actual values (not just
// placeholders)
const defaultValues = {
  // title: "Episode Title",
  // description: "Episode Description",
  // durationInMicroseconds: BigInt(100), // todo: determine this from the linked media
  // uri: "www.example.com/test.mp4",
};

const PutEpisodeForm = (): JSX.Element => {
  const { actor, authClient, login, profile } = useContext(AppContext);
  const { state } = useLocation();
  const [searchParams] = useSearchParams();
  const [feedKey, setFeedKey] = useState(searchParams.get('feed'));
  const { feed: incomingFeed, episode } = state as PutEpisodeFormProps || {};
  const [feed, setFeed] = useState(incomingFeed);
  const navigate = useNavigate();
  const { register, getValues, setValue, handleSubmit, formState: { errors } } = useForm<Submission>();//{ defaultValues });

  const allFieldsAreEmpty = () => {
    const values = getValues();
    for (const [k, v] of Object.entries(values)) {
      if (typeof v != "string") {
        throw "Encountered non-string value in form. allFieldsAreEmpty may need to be updated to know what to expect for a 'blank' value for that type";
      }
      if (v as string != "") {
        return false;
      }
    }
    return true;
  }

  const populate = async (episode: Episode) => {
    setValue('description', episode.description, { shouldValidate: true });
    setValue('title', episode.title, { shouldValidate: true });
    if (actor) {
      let mediaResult = await actor.getMedia(episode.mediaId);
      if (mediaResult.length == 1) {
        let media: Media = mediaResult[0];
        setValue('uri', media.uri, { shouldValidate: true });
      }
    };
  };

  useEffect(() => {
    if (episode) {
      populate(episode);
    };
  }, []);

  useEffect(() => {
    // If we weren't initialized with a feed, fetch the one at feedKey
    if (!feed) {
      if (actor && feedKey) {
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
  }, [actor]);

  // todo: break this out into a reusable component
  if (authClient == null || actor == null) {
    return (
      <Section>
        <h3>Please authenticate before adding episodes</h3>
        <Button variant="cta" onPress={login}>
          Login with&nbsp;
          <Icon>
            <Loop />
          </Icon>
        </Button>
      </Section>
    );
  };

  const copyFromRecent = async () => {
    const mostRecentEpisodeId = feed?.episodeIds.at(feed?.episodeIds.length - 1);
    if (!mostRecentEpisodeId) {
      alert("No previous episode found to copy values from");
    } else {
      let episodeResult = await actor.getEpisode(feed!.key, mostRecentEpisodeId);
      if (episodeResult.length == 1) {
        let mostRecentEpisode = episodeResult[0];
        if (allFieldsAreEmpty() || window.confirm("Are you sure you want to replace all form values with values from episode titled \"" + mostRecentEpisode.title + "\"?")) {
          populate(mostRecentEpisode);
        };
      }
    }
  };

  const onSubmit = async (data: Submission): Promise<void> => {
    if (!feed) {
      toast.error("Please wait for feed to be fetched, or refresh");
      console.error("Feed is undefined at time of form submission");
      return;
    };

    // Until we want to reuse Media in multiple Episodes, we add a new Media
    // for every Episode using mostly dummy information for now
    const mediaData: MediaData = {
      source: {
        id: "roF5zFCgAhc",
        uri: "https://www.youtube.com/watch?v=roF5zFCgAhc",
        platform: {
          id: "youtube",
          uri: "www.youtube.com",
        },
        releaseDate: "1970-01-01T00:00:00.000Z",
      },
      durationInMicroseconds: BigInt(100),
      uri: data.uri,
      etag: "example",
      lengthInBytes: BigInt(100),
    };

    // Submit the Media to receive the MediaID, which we need for the Episode
    let mediaAddResult = await actor!.addMedia(mediaData);
    if ("ok" in mediaAddResult) {
      toast.success("Media successfully added!");
    } else {
      toast.error("Error when adding Media");
      console.error(mediaAddResult.err);
      return;
    };
    let mediaId = mediaAddResult.ok.id;

    // Add the Episode
    const episodeData: EpisodeData = {
      feedKey: feed.key,
      title: data.title,
      description: data.description,
      mediaId: mediaId,
    };

    let addEpisodeResult = await actor!.addEpisode(episodeData);
    if ("ok" in addEpisodeResult) {
      toast.success("Episode successfully added!");
      navigate('/listEpisodes?feed=' + feedKey, { state: { feedInfo: { key: feedKey, feed } } });
    } else {
      if ("FeedNotFound" in addEpisodeResult.err) {
        toast.error("Feed not found: " + feedKey);
      } else {
        toast.error("Error adding episode.");
      }
      console.error(addEpisodeResult.err);
    }
  };

  if (!feedKey) {
    return <h1>feed must be specified as a search param so we know which feed to add the episode to.</h1>
  };

  if (!profile) {
    return <h1>Fetching profile...</h1>
  };

  if (!profile.ownedFeedKeys.includes(feedKey)) {
    return <h1>You do not own the "{feedKey}" feed. You can only edit episodes for feeds you own.</h1>
  };

  return (
    <FormContainer>
      <div style={{ display: 'flex' }}>
        <div style={{ flex: '1', paddingRight: '15px' }}>
          <div style={{ float: "left" }}>
            <Title>{episode ? "Edit episode" : "Add episode to your \"" + feedKey + "\" feed"}</Title>
          </div>
        </div>
        {
          feed && feed.episodeIds.length > 0 ?
            <div style={{ flex: "1", paddingLeft: "15px" }}>
              <ActionButton onPress={copyFromRecent}>Copy previous episode's values</ActionButton>
            </div> : null
        }
      </div>
      <form onSubmit={handleSubmit(onSubmit)}>
        <Label>
          Title:
          <Input
            {...register("title", { required: "Title is required" })}
            placeholder="Episode Title" />
          <ValidationError>{errors.title?.message}</ValidationError>
        </Label>

        <Label>
          Description:
          <br />
          <div className="input-sizer stacked">
            <GrowableInput
              {...register("description", {
                required: "Description is required",
                onChange: (e) => { e.target.parentNode.dataset.value = e.target.value; }
              })}
              placeholder="Episode Description" />
          </div>
          <ValidationError>{errors.description?.message}</ValidationError>
        </Label>

        {/* todo: Add Summary and Content Encoded so they can be set separately from the Description */}

        <Label>
          Media URL:
          <Input
            {...register("uri", { required: "Media URL is required" })}
            placeholder="www.example.com/test.mp4" />
          <ValidationError>{errors.uri?.message}</ValidationError>
        </Label>

        <LargeBorderWrap>
          <LargeBorder>
            <LargeButton type="submit" />
          </LargeBorder>
        </LargeBorderWrap>
      </form>
    </FormContainer >
  );
};

export default PutEpisodeForm;
