import { ActorSubclass } from "@dfinity/agent";
import React from "react";
import {
  Feed,
  ProfileUpdate,
  _SERVICE,
} from "../../../declarations/serve/serve.did";
import { emptyProfile } from "../hooks";
import { useForm } from "react-hook-form";

export const CreateFeedForm = (): JSX.Element => {

  const { register, handleSubmit, formState: { errors } } = useForm<Feed>();
  const onSubmit = (data: Feed): void => {
    console.log(data);
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
          Summary:
          <input {...register("description", { required: "Description is required" })} />
          <p>{errors.description?.message}</p>
        </label>

        <label>
          Owner Name:
          <input {...register("author", { required: "Owner name is required" })} />
          <p>{errors.author?.message}</p>
        </label>

        <label>
          Owner Email:
          <input {...register("email", { required: "Email is required", pattern: { value: /.+@.+/, message: "Email should be in xxx@yyy.zzz format" } })} />
          <p>{errors.email?.message}</p>
        </label>

        <label>
          Image URL:
          <input {...register("imageUrl", { required: "Image URL is required" })} />
          <p>{errors.imageUrl?.message}</p>
        </label>

        <input type="submit" />
      </form>
    </div>
  );
};
