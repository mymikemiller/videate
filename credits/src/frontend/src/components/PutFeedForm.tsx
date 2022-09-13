// Create a new feed or modify an existing feed (existing feeds must be owned
// by the current user in order to edit)
import React, { useContext, useEffect, useState } from "react";
import {
  useNavigate,
} from "react-router-dom";
import { useSearchParams, useLocation } from 'react-router-dom';
import {
  Feed,
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
  type PutFeedInfo = Feed & { key: string };
  const { register, handleSubmit, setValue, formState: { errors } } = useForm<PutFeedInfo>();//{ defaultValues });

  const populate = (init: PutFeedFormProps): void => {
    if (init.key) {
      setValue('key', init.key, { shouldValidate: true });
    }
    if (init.feed) {
      setValue('title', init.feed.title, { shouldValidate: true });
      setValue('description', init.feed.description, { shouldValidate: true });
      setValue('imageUrl', init.feed.imageUrl, { shouldValidate: true });
      setValue('author', init.feed.author, { shouldValidate: true });
      setValue('email', init.feed.email, { shouldValidate: true });
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

  const onSubmit = (data: PutFeedInfo): void => {
    const feed: Feed = {
      ...data,
      link: "test.com", //todo: generate correct link using the key and the user's principal
      mediaList: [],
      subtitle: "test subtitle",
      owner: authClient.getIdentity().getPrincipal(), // Feeds are always owned by the user who created them.
    };

    // Handle update async
    actor!.putFeed(data.key, feed).then(async (result: PutFeedFullResult) => {
      if ("ok" in result) {
        if ("Created" in result.ok) {
          toast.success("New feed created!");
          if (profile) {
            profile.ownedFeedKeys.push(data.key);
          } else {
            console.error("Profile does not exist at the time of adding feed, so the UI won't know we own the new feed.")
          }
          navigate('/putMedia?feedKey=' + data.key, { state: { feedKey: data.key, feed } })
        } else if ("Updated" in result.ok) {
          toast.success("Feed updated!");
          navigate('/manageFeeds');
        }
        return result.ok;
      } else {
        if ("KeyExists" in result.err) {
          toast.error("There is already a feed with this key. Key must be unique among all Videate feeds.");
        } else {
          toast.error("Error creating feed.");
        }
        console.error(result.err);
        return;
      }
    });
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
              pattern: { value: /^[a-zA-Z0-9_-]*$/, message: "Feed Key must contain only letters, numbers, underscores (_) and dashes (-)" }
            })}
            disabled={init?.key != null} // Disable this field if we're editing an existing feed (in which case we can't change the key since people may be subscribed to it)
            placeholder="Unique Feed Key" />
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
