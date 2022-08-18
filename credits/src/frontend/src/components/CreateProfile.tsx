import React from "react"; // import * as React from 'react'
import {
  ProfileUpdate,
  _SERVICE,
} from "../../../declarations/serve/serve.did";
import ProfileForm from "./ProfileForm";
import toast from "react-hot-toast";
import { emptyProfile } from "../hooks";
import { useContext, useEffect } from "react"; // import * as React from 'react'
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

  const submitCallback = async (profileUpdate: ProfileUpdate) => {
    // Handle creation and verification async
    actor?.createContributor(profileUpdate).then(async (createResponse) => {
      if ("ok" in createResponse) {
        const profileResponse = await actor.readContributor();
        if ("ok" in profileResponse) {
          setProfile(profileResponse.ok);
        } else {
          console.error(profileResponse.err);
          handleCreationError();
        }
      } else {
        handleCreationError();
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
