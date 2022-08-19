import { ActorSubclass } from "@dfinity/agent";
import {
  ActionButton,
  ButtonGroup,
  Grid,
  Heading,
  Text,
} from "@adobe/react-spectrum";
import Cancel from "@spectrum-icons/workflow/Cancel";
import Delete from "@spectrum-icons/workflow/Delete";
import Edit from "@spectrum-icons/workflow/Edit";
import React, { useEffect, useState } from "react"; // import * as React from 'react'
import { useContext } from "react";
import toast from "react-hot-toast";
import { useNavigate } from "react-router-dom";
import styled from "styled-components";
import {
  Profile,
  ProfileUpdate,
  _SERVICE,
} from "../../../declarations/serve/serve.did";
import { AppContext } from "../App";
import { emptyProfile } from "../hooks";
import { pushProfileUpdate } from "../utils";
import CopyableLink from "./CopyableLink";
import ProfileForm from "./ProfileForm";
import { canisterId as serveCid, createActor as createServeActor } from "../../../declarations/serve";
import { _SERVICE as _SERVE_SERVICE } from "../../../declarations/serve/serve.did";

const DetailsList = styled.dl`
  dd {
    margin-left: 0;
  }
`;

function ManageProfile() {
  const [isEditing, setIsEditing] = useState(false);
  const [serveActor, setServeActor] = useState<ActorSubclass<_SERVE_SERVICE>>();
  const { actor, profile, setProfile } = useContext(AppContext);
  const navigate = useNavigate();

  const initServeActor = () => {
    const sActor = createServeActor(serveCid as string);
    setServeActor(sActor);
  };

  useEffect(() => {
    initServeActor();
  }, []);

  const deleteProfile = async () => {
    if (
      confirm(
        "Are you sure you want to delete your contributor profile? This will be permanent!"
      )
    ) {
      const result = await actor?.deleteContributor();
      toast.success("Contributor profile successfully deleted");
      navigate("/");
    }
  };

  const submitCallback = (profileUpdate: ProfileUpdate) => {
    setIsEditing(false);

    // Handle update async
    pushProfileUpdate(actor!, profileUpdate).then(async (profile: Profile | undefined) => {
      if (profile) {
        toast.success("Contributor profile updated!");
        setProfile(profile);
        navigate('/manage');
      }
    });
  };

  const formProps = {
    submitCallback,
    actor,
    profile: profile ?? emptyProfile,
  };

  if (!profile) {
    return null;
  }

  const { name } = profile.bio;
  const { feedKeys } = profile;

  // Greet the user
  let fallbackDisplayName = name;
  if (name[0]) fallbackDisplayName = name;

  if (serveActor == undefined) {
    return null;
  }

  return (
    <>
      {isEditing ? (
        <section key={String(isEditing)}>
          <Heading level={2}>Editing Profile</Heading>
          <ProfileForm {...formProps} />
          <ActionButton
            onPress={(e) => {
              setIsEditing(false);
            }}
          >
            <Cancel /> <Text>Cancel</Text>
          </ActionButton>
        </section>
      ) : (
        <section key={String(isEditing)}>
          <Heading level={2}>
            Welcome back
            {fallbackDisplayName[0] ? `, ${fallbackDisplayName[0]}` : ""}!
          </Heading>
          {feedKeys.length == 0 && <Text>No feed keys found. Please click the Videate link in the shownotes to populate.</Text>}
          <ul style={{ padding: 0 }} >
            {feedKeys.map((feedKey, index) => {
              return (
                <li key={feedKey} style={{ listStyleType: 'none', marginBottom: '1em' }} >
                  <CopyableLink serveActor={serveActor!} feedKey={feedKey} />
                </li>
              )
            })}
          </ul>
          <ButtonGroup>
            <ActionButton onPress={() => setIsEditing(true)}>
              <Edit />
              <Text>Edit</Text>
            </ActionButton>
            <ActionButton onPress={deleteProfile}>
              <Delete /> <Text>Delete</Text>
            </ActionButton>
          </ButtonGroup>
        </section>
      )}
    </>
  );
}

export default ManageProfile;
