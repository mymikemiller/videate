import React, { useContext } from "react";
import {
  Feed,
  AddFeedResult,
  _SERVICE,
} from "../../../declarations/serve/serve.did";
import Loop from "../../assets/loop.svg";
import { useForm } from "react-hook-form";
import { pushNewFeed } from "../utils";
import { AppContext } from "../App";
import toast from "react-hot-toast";
import { Button, Icon } from "@adobe/react-spectrum";
import styled from "styled-components";

const Section = styled.section`
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
`;

const CreateFeedForm = (): JSX.Element => {
  type AddFeedInfo = Feed & { key: string };
  const { actor, authClient, login } = useContext(AppContext);

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

  const defaultValues = {
    key: "test",
    title: "Test Feed Title",
    description: "Test Feed Description",
    imageUrl: "imageurl.com",
    author: "Test Test",
    email: "test@example.com",
  };

  const { register, handleSubmit, formState: { errors } } = useForm<AddFeedInfo>({ defaultValues });
  const onSubmit = (data: AddFeedInfo): void => {
    const feed: Feed = {
      ...data,
      link: "test.com", //todo: generate correct link using the key and the user's principal
      mediaList: [],
      subtitle: "test subtitle",
    };

    // Handle update async
    pushNewFeed(actor!, feed, data.key).then(async (result: AddFeedResult) => {
      if ("ok" in result) {
        toast.success("New feed created!");
        // todo: navigate to the add media page: navigate('/addMedia');
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
    <div className="App">
      <form onSubmit={handleSubmit(onSubmit)}>

        <label>
          Key:
          <input {...register("key", { required: "Feed Key is required" })} />
          <p>{errors.key?.message}</p>
        </label>

        <label>
          Title:
          <input {...register("title", { required: "Title is required" })} />
          <p>{errors.title?.message}</p>
        </label>

        <label>
          Summary:
          <input {...register("description", { required: "Description is required" })} />
          <p>{errors.description?.message}</p>
        </label>

        {/* todo: Add Description and Content Encoded so they can be set separately from the Summary */}

        <label>
          Image URL:
          <input {...register("imageUrl", { required: "Image URL is required" })} />
          <p>{errors.imageUrl?.message}</p>
        </label>

        {/* todo: Automatically use Owner Name and Owner from uploader profile? */}

        <label>
          Owner Name:
          <input {...register("author", { required: "Owner name is required" })} />
          <p>{errors.author?.message}</p>
        </label>

        <label>
          Owner Email:
          <input {...register("email", {
            required: "Email is required",
            pattern: { value: /.+@.+/, message: "Email should be in xxx@yyy.zzz format" }
          })} />
          <p>{errors.email?.message}</p>
        </label>

        {/* todo: add Category dropdowns */}

        <input type="submit" />
      </form>
    </div>
  );
};

export default CreateFeedForm;
