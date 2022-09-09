import React, { useContext, useState, useEffect } from "react";
import { useSearchParams } from 'react-router-dom';
import {
  PutMediaResult,
  _SERVICE,
  Media,
  Feed,
} from "../../../declarations/serve/serve.did";
import Loop from "../../assets/loop.svg";
import { useForm } from "react-hook-form";
import { pushNewMedia } from "../utils";
import { AppContext } from "../App";
import toast from "react-hot-toast";
import { Button, ActionButton, Icon } from "@adobe/react-spectrum";
import { Section, FormContainer, Title, Label, Input, GrowableInput, LargeButton, LargeBorder, LargeBorderWrap, ValidationError } from "./styles/styles";

// We'll use dummy information for now, so we omit the fields we don't ask for
type MediaSubmission = Omit<Media, "source" | "durationInMicroseconds" | "nftTokenId" | "etag" | "lengthInBytes">;

interface AddMediaFormProps {
  feed?: Feed; // If feed is provided, use that feed instead of fetching the feed using the the feedKey query param on load
};

// Specify defaultValues to pre-fill the form with actual values (not just
// placeholders)
const defaultValues = {
  // title: "Episode Title",
  // description: "Episode Description",
  // durationInMicroseconds: BigInt(100), // todo: determine this from the linked media
  // uri: "www.example.com/test.mp4",
};

const AddMediaForm = ({ feed: incomingFeed }: AddMediaFormProps): JSX.Element => {
  const { actor, authClient, login } = useContext(AppContext);
  const [searchParams] = useSearchParams();
  const feedKey = searchParams.get('feedKey');
  const [feed, setFeed] = useState(incomingFeed);
  const { register, setValue, handleSubmit, formState: { errors } } = useForm<MediaSubmission>({ defaultValues });

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
        <h3>Please authenticate before adding media</h3>
        <Button variant="cta" onPress={login}>
          Login with&nbsp;
          <Icon>
            <Loop />
          </Icon>
        </Button>
      </Section>
    );
  };

  const copyPreviousValues = (): void => {
    const previousMedia = feed?.mediaList.at(feed?.mediaList.length - 1);
    if (previousMedia) {
      setValue('title', previousMedia.title, { shouldValidate: true });
      setValue('description', previousMedia.description, { shouldValidate: true });
      setValue('uri', previousMedia.uri, { shouldValidate: true });
    }
  };

  const onSubmit = (data: MediaSubmission): void => {
    // Add in dummy information for now
    const media: Media = {
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
    pushNewMedia(actor!, feedKey!, media).then(async (result: PutMediaResult) => {
      if ("ok" in result) {
        toast.success("Media successfully added!");
      } else {
        if ("FeedNotFound" in result.err) {
          toast.error("Feed not found: " + feedKey);
        } else {
          toast.error("Error adding media.");
        }
        console.error(result.err);
      }
    });
  };

  if (!feedKey) {
    return <h1>feedKey must be specified as a query parameter so we know which feed to add media to.</h1>
  };

  return (
    <FormContainer>
      <div style={{ display: 'flex' }}>
        <div style={{ flex: '1', paddingRight: '15px' }}>
          <div style={{ float: "right" }}>
            <Title>Add media to your "{feedKey}" Feed</Title>
          </div>
        </div>
        {
          feed && feed.mediaList.length > 0 ?
            <div style={{ flex: "1", paddingLeft: "15px" }}>
              <ActionButton onPress={() => { window.confirm("Are you sure you want to replace all values with the previous episode's values?") && copyPreviousValues() }}>Copy previous episode's values</ActionButton>
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

export default AddMediaForm;
