import React, { useContext } from "react";
import {
  useNavigate,
} from "react-router-dom";
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
import { Section, FormContainer, Title, Label, Input, GrowableInput, LargeButton, LargeBorder, LargeBorderWrap, ValidationError } from "./styles/styles";

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

const CreateFeedForm = (): JSX.Element => {
  const { actor, authClient, login } = useContext(AppContext);
  const navigate = useNavigate();
  type AddFeedInfo = Feed & { key: string };
  const { register, handleSubmit, formState: { errors } } = useForm<AddFeedInfo>({ defaultValues });

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

  const onSubmit = (data: AddFeedInfo): void => {
    const feed: Feed = {
      ...data,
      link: "test.com", //todo: generate correct link using the key and the user's principal
      mediaList: [],
      subtitle: "test subtitle",
      owner: authClient.getIdentity().getPrincipal(), // Feeds are always owned by the user who created them.
    };

    // Handle update async
    pushNewFeed(actor!, feed, data.key).then(async (result: AddFeedResult) => {
      if ("ok" in result) {
        toast.success("New feed created!");
        navigate('/addMedia?feedKey=' + data.key);
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
      <Title>Create new Podcast</Title>
      <form onSubmit={handleSubmit(onSubmit)}>

        <Label>
          Key:
          <Input
            {...register("key", {
              required: "Feed Key is required",
              pattern: { value: /^[a-zA-Z0-9_-]*$/, message: "Feed Key must contain only letters, numbers, underscores (_) and dashes (-)" }
            })}
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

export default CreateFeedForm;
