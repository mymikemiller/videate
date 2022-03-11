import { remove, set } from "local-storage";
import React from "react";
import {
  ProfileUpdate,
  _SERVICE,
} from "../../../declarations/contributor/contributor.did";
import ProfileForm from "./ProfileForm";
import toast from "react-hot-toast";
import { emptyProfile } from "../hooks";
import { useContext } from "react";
import { AppContext } from "../App";
import { useEffect } from "react";

const CreateProfile = () => {
  const { setIsAuthenticated, isAuthenticated, actor, profile, updateProfile } =
    useContext(AppContext);

  useEffect(() => {
    console.log("profile", profile);
  }, [profile, isAuthenticated]);

  function handleCreationError() {
    remove("profile");
    setIsAuthenticated?.(false);
    updateProfile?.(emptyProfile);
    toast.error("There was a problem creating your profile");
  }

  const submitCallback = async (profile: ProfileUpdate) => {
    // Save profile locally
    set("profile", JSON.stringify(profile));

    // Optimistic update
    updateProfile?.(profile);
    toast.success("Profile created");

    // Handle creation and verification async
    actor?.create(profile).then(async (createResponse) => {
      if ("ok" in createResponse) {
        const profileResponse = await actor.read();
        if ("ok" in profileResponse) {
          // Do nothing, we already updated
        } else {
          console.error(profileResponse.err);
          handleCreationError();
        }
      } else {
        handleCreationError();
        remove("ic-delegation");
        console.error(createResponse.err);
      }
    });
  };

  return (
    <ProfileForm
      submitCallback={submitCallback}
      actor={actor}
      profile={emptyProfile}
    />
  );
};

export default CreateProfile;
