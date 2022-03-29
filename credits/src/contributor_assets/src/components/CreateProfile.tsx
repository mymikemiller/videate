import React from "react";
import {
  ProfileUpdate,
  _SERVICE,
} from "../../../declarations/contributor/contributor.did";
import ProfileForm from "./ProfileForm";
import toast from "react-hot-toast";
import { emptyProfile } from "../hooks";
import { useContext, useEffect } from "react";
import { AppContext } from "../App";
import { useNavigate } from "react-router-dom";

const CreateProfile = () => {
  const navigate = useNavigate();
  const { setIsAuthenticated, isAuthenticated, actor, profile, setProfile } =
    useContext(AppContext);

  function handleCreationError() {
    setIsAuthenticated?.(false);
    setProfile?.(emptyProfile);
    toast.error("There was a problem creating your profile");
  }

  const submitCallback = async (profile: ProfileUpdate) => {
    // Handle creation and verification async
    actor?.create(profile).then(async (createResponse) => {
      if ("ok" in createResponse) {
        const profileResponse = await actor.read();
        if ("ok" in profileResponse) {
          navigate('/manage');
        } else {
          console.error(profileResponse.err);
          handleCreationError();
        }
      } else {
        handleCreationError();
        console.log("there was an error in profile creation:");
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
