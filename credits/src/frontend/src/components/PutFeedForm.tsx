// Create a new feed or modify an existing feed (existing feeds must be owned
// by the current user in order to edit)
import React, { useContext, useEffect, useState } from "react";
import {
  useNavigate,
} from "react-router-dom";
import { useSearchParams, useLocation } from 'react-router-dom';
import {
  Feed,
  Episode,
  EpisodeID,
  PutFeedFullResult,
  _SERVICE,
} from "../../../declarations/serve/serve.did";
import Loop from "../../assets/loop.svg";
import { useForm } from "react-hook-form";
import { AppContext } from "../App";
import toast from "react-hot-toast";
import { Button, Icon } from "@adobe/react-spectrum";
import { Section, FormContainer, Title, Label, Input, GrowableInput, LargeButton, LargeBorder, LargeBorderWrap, ValidationError } from "./styles/styles";

interface PutFeedFormProps {
  // If feed is provided, pre-populate the form with its values. If key is
  // provided, assume we're editing a feed and lock the feedKey to that value.
  // If no feed is provided, but feedKey is, fetch the feed at that key and,
  // after verifying ownership, pre-populate with that feed's data. If neither
  // are specified, assume we're creating a new feed.
  key?: string;
  feed?: Feed;
};

// Specify defaultValues to pre-fill the form with actual values (not just
// placeholders)
const defaultValues = {
  // key: "test",
  // title: "Test Feed Title",
  // description: "Test Feed Description",
  // imageUrl: "imageurl.com",
  // author: "Test Test",
  // email: "test@example.com",
};

const PutFeedForm = (): JSX.Element => {
  const { actor, authClient, profile, setProfile, login } = useContext(AppContext);
  const { state } = useLocation();
  const init = state as PutFeedFormProps;
  const navigate = useNavigate();
  const { register, handleSubmit, setValue, formState: { errors } } = useForm<Feed>();//{ defaultValues });
  const [episodeIds, setEpisodeIds] = useState<EpisodeID[]>();

  const populate = (init: PutFeedFormProps): void => {
    if (init.key) {
      setValue('key', init.key, { shouldValidate: true });
    }
    if (init.feed) {
      setValue('key', init.feed.key, { shouldValidate: true });
      setValue('title', init.feed.title, { shouldValidate: true });
      setValue('description', init.feed.description, { shouldValidate: true });
      setValue('imageUrl', init.feed.imageUrl, { shouldValidate: true });
      setValue('author', init.feed.author, { shouldValidate: true });
      setValue('email', init.feed.email, { shouldValidate: true });

      // Store the EpisodeIDs separately from the form since we don't edit the
      // episode list here. We store it in state so we can restore it before
      // submitting the feed so it doesn't get blown away.
      setEpisodeIds(init.feed.episodeIds);
    }
  };

  useEffect(() => {
    if (init) {
      populate(init);
    };
  }, []);

  // todo: break this out into a reusable component
  if (authClient == null || actor == null) {
    return (
      <Section>
        <h3>Please authenticate before adding a feed</h3>
        <Button variant="cta" onPress={login}>
          Login with&nbsp;
          <Icon>
            <Loop />
          </Icon>
        </Button>
      </Section>
    );
  };

  const onSubmit = async (feed: Feed): Promise<void> => {
    feed.link = "http://www.test.com"; //todo: generate correct link using the key and the user's principal
    feed.episodeIds = episodeIds ?? [];
    feed.subtitle = "test subtitle";
    feed.owner = authClient.getIdentity().getPrincipal(); // Feeds are always owned by the user who created them.

    // Handle update async
    let putFeedResult = await actor!.putFeed(feed);
    if ("ok" in putFeedResult) {
      // Fetch the newly updated profile so the page we navigate to will be correct
      let newProfileResult = await actor!.readContributor();
      if ("ok" in newProfileResult) {
        await setProfile(newProfileResult.ok);
      };

      if ("Created" in putFeedResult.ok) {
        toast.success("New feed created!");
        navigate('/putEpisode?feed=' + feed.key, { state: { feed } });
      } else if ("Updated" in putFeedResult.ok) {
        toast.success("Feed updated!");
        navigate('/manageFeeds');
      }
      return;
    } else {
      if ("KeyExists" in putFeedResult.err) {
        toast.error("There is already a feed with this key. Key must be unique among all feeds.");
      } else {
        toast.error("Error creating feed.");
      }
      console.error(putFeedResult.err);
      return;
    };
  };

  return (
    <FormContainer>
      <Title>{init == null ? "Create new Feed" : "Edit \"" + init.key + "\" Feed"}</Title>
      <form onSubmit={handleSubmit(onSubmit)}>

        <Label>
          Key:
          <Input
            {...register("key", {
              required: "Feed Key is required",
              pattern: { value: /^[a-z0-9-]*$/, message: "Feed Key must contain only lower case letters, numbers and dashes (-)" }
            })}
            disabled={init?.key != null} // Disable this field if we're editing an existing feed (in which case we can't change the key since people may be subscribed to it)
            placeholder="Unique Feed Key"
            // Only allow lower case keys and replace spaces with dashes
            onChange={event => setValue("key", event.target.value.toLowerCase().replace(' ', '-'))} />
          <ValidationError>{errors.key?.message}</ValidationError>
        </Label>

        <Label>
          Title:
          <Input
            {...register("title", { required: "Title is required" })}
            placeholder="Feed Title" />
          <ValidationError>{errors.title?.message}</ValidationError>
        </Label>

        <Label>
          Description:
          <br />
          <div className="input-sizer stacked">
            <GrowableInput
              {...register("description", {
                required: "Description is required",
                onChange: (e) => { e.target.parentNode.dataset.value = e.target.value }
              })}
              placeholder="Feed Description" />
          </div>
          <ValidationError>{errors.description?.message}</ValidationError>
        </Label>

        {/* todo: Add Summary and Content Encoded so they can be set separately from the Description */}

        <Label>
          Image URL:
          <Input
            {...register("imageUrl", { required: "Image URL is required" })}
            placeholder="www.example.com/test.jpg" />
          <ValidationError>{errors.imageUrl?.message}</ValidationError>
        </Label>

        {/* todo: Automatically use Owner Name and Owner Email from uploader profile? */}

        <Label>
          Owner Name:
          <Input
            {...register("author", { required: "Owner name is required" })}
            placeholder="John Doe" />
          <ValidationError>{errors.author?.message}</ValidationError>
        </Label>

        <Label>
          Owner Email:
          <Input
            {...register("email", {
              required: "Email is required",
              pattern: { value: /.+@.+/, message: "Email should be in xxx@yyy.zzz format" }
            })}
            placeholder="john_doe@example.com" />
          <ValidationError>{errors.email?.message}</ValidationError>
        </Label>

        {/* todo: add Category dropdowns */}

        <LargeBorderWrap>
          <LargeBorder>
            <LargeButton type="submit" />
          </LargeBorder>
        </LargeBorderWrap>
      </form>
    </FormContainer>
  );
};

export default PutFeedForm;
