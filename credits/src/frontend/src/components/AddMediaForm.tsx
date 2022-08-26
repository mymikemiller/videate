import React, { useContext } from "react";
import {
  PutMediaResult,
  _SERVICE,
  Media,
} from "../../../declarations/serve/serve.did";
import Loop from "../../assets/loop.svg";
import { useForm } from "react-hook-form";
import { pushNewMedia } from "../utils";
import { AppContext } from "../App";
import toast from "react-hot-toast";
import { Button, Icon } from "@adobe/react-spectrum";
import styled from "styled-components";

// We'll use dummy information for now, so we omit the fields we don't ask for
type MediaSubmission = Omit<Media, "source" | "durationInMicroseconds" | "nftTokenId" | "etag" | "lengthInBytes">;

const Section = styled.section`
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
`;


interface AddMediaFormProps {
  feedKey: string;
};

const AddMediaForm = ({ feedKey }: AddMediaFormProps): JSX.Element => {
  const { actor, authClient, login } = useContext(AppContext);

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

  const defaultValues = {
    title: "Episode Title",
    description: "Test Episode Description",
    // durationInMicroseconds: BigInt(100), // todo: determine this from the linked media
    uri: "www.example.com/test.mp4",
  };

  const { register, handleSubmit, formState: { errors } } = useForm<MediaSubmission>({ defaultValues });
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
    pushNewMedia(actor!, feedKey, media).then(async (result: PutMediaResult) => {
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

  return (
    <div className="App">
      <form onSubmit={handleSubmit(onSubmit)}>

        <label>
          Title:
          <input {...register("title", { required: "Title is required" })} />
          <p>{errors.title?.message}</p>
        </label>

        <label>
          Description:
          <input {...register("description", { required: "Description is required" })} />
          <p>{errors.description?.message}</p>
        </label>

        {/* todo: Add Summary and Content Encoded so they can be set separately from the Description */}

        <label>
          Media URL:
          <input {...register("uri", { required: "Media URL is required" })} />
          <p>{errors.uri?.message}</p>
        </label>

        <input type="submit" />
      </form>
    </div>
  );
};

export default AddMediaForm;
