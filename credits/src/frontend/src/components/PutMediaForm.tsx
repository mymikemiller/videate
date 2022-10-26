import React, { useContext, useState, useEffect } from "react";
import { useSearchParams, useLocation, useNavigate } from 'react-router-dom';
import {
  PutEpisodeResult,
  _SERVICE,
  Episode,
  Feed,
} from "../../../declarations/serve/serve.did";
import Loop from "../../assets/loop.svg";
import { useForm } from "react-hook-form";
import { AppContext } from "../App";
import toast from "react-hot-toast";
import { Button, ActionButton, Icon } from "@adobe/react-spectrum";
import { Section, FormContainer, Title, Label, Input, GrowableInput, LargeButton, LargeBorder, LargeBorderWrap, ValidationError } from "./styles/styles";

// We'll use dummy information for now, so we omit the fields we don't ask for
type EpisodeSubmission = Omit<Episode, "source" | "durationInMicroseconds" | "nftTokenId" | "etag" | "lengthInBytes">;

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
  const [feedKey, setFeedKey] = useState(searchParams.get('feedKey'));
  const { feed: incomingFeed, episode } = state as PutEpisodeFormProps || {};
  const [feed, setFeed] = useState(incomingFeed);
  const navigate = useNavigate();
  const { register, getValues, setValue, handleSubmit, formState: { errors } } = useForm<EpisodeSubmission>();//{ defaultValues });

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

  const populate = (episode: Episode): void => {
    setValue('title', episode.title, { shouldValidate: true });
    setValue('description', episode.description, { shouldValidate: true });
    setValue('uri', episode.uri, { shouldValidate: true });
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

  const confirmAndCopyOverMostRecentEpisodeValues = (): void => {
    const mostRecentEpisode = feed?.episodes.at(feed?.episodes.length - 1);
    if (!mostRecentEpisode) {
      window.prompt("No previous episode found to copy values from");
    } else {
      if (allFieldsAreEmpty() || window.confirm("Are you sure you want to replace all form values with values from episode titled \"" + mostRecentEpisode.title + "\"?")) {
        populate(mostRecentEpisode);
      };
    }
  };

  const onSubmit = (data: EpisodeSubmission): void => {
    // Add in dummy information for now
    const episode: Episode = {
      ...data,
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
      nftTokenId: [],
      etag: "example",
      lengthInBytes: BigInt(100),
    };

    // Handle update async
    actor!.putEpisode(feedKey!, episode).then(async (result: PutEpisodeResult) => {
      if ("ok" in result) {
        toast.success("Episode successfully added!");
        navigate('/listEpisodes?feedKey=' + feedKey, { state: { feedInfo: { key: feedKey, feed } } });
      } else {
        if ("FeedNotFound" in result.err) {
          toast.error("Feed not found: " + feedKey);
        } else {
          toast.error("Error adding episode.");
        }
        console.error(result.err);
      }
    });
  };

  if (!feedKey) {
    return <h1>feedKey must be specified as a search param so we know which feed to add the episode to.</h1>
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
          feed && feed.episodes.length > 0 ?
            <div style={{ flex: "1", paddingLeft: "15px" }}>
              <ActionButton onPress={confirmAndCopyOverMostRecentEpisodeValues}>Copy previous episode's values</ActionButton>
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
