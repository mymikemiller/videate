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
import * as React from "react";
import { useContext } from "react";
import toast from "react-hot-toast";
import { useNavigate } from "react-router-dom";
import styled from "styled-components";
import {
  ProfileUpdate,
  _SERVICE,
} from "../../../declarations/contributor/contributor.did";
import { AppContext } from "../App";
import { emptyProfile } from "../hooks";
import { compareProfiles } from "../utils";
import ProfileForm from "./ProfileForm";

const DetailsList = styled.dl`
  dd {
    margin-left: 0;
  }
`;

function ManageProfile() {
  const [isEditing, setIsEditing] = React.useState(false);
  const { actor, profile, setProfile, isAuthenticated } = useContext(AppContext);
  const navigate = useNavigate();

  const deleteProfile = async () => {
    if (
      confirm(
        "Are you sure you want to delete your contributor profile? This will be permanent!"
      )
    ) {
      const result = await actor?.delete();
      toast.success("Contributor profile successfully deleted");
      console.log(result);
      navigate("/");
    }
  };

  const compare = (updatedProfile: ProfileUpdate) => {
    return compareProfiles(profile, updatedProfile);
  };

  const submitCallback = (profile: ProfileUpdate) => {
    toast.success("Contributor profile updated!");
    setIsEditing(false);

    // Handle update async
    actor?.update(profile).then(async (profileUpdate) => {
      if ("ok" in profileUpdate) {
        const profileResponse = await actor.read();
        if ("ok" in profileResponse) {
          // Don't do anything if there is no difference.
          if (!compare(profileResponse.ok)) return;

          setProfile?.(profileResponse.ok);
          navigate('/manage');
        } else {
          console.error(profileResponse.err);
          toast.error("Failed to read profile from IC");
        }
      } else {
        console.error(profileUpdate.err);
        toast.error("Failed to save update to IC");
      }
    });
  };

  const formProps = {
    submitCallback,
    actor,
    profile: profile ?? emptyProfile,
  };

  if (!profile) {
    console.log('There is no profile, so returning null for ManageProfile component');
    return null;
  }

  const { name } = profile.bio;

  // Greet the user
  let fallbackDisplayName = name;
  if (name[0]) fallbackDisplayName = name;

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
          <DetailsList>
            <Grid columns="1fr 1fr" gap="1rem">
              <dd>Name:</dd>
              <dt>{name}</dt>
            </Grid>
          </DetailsList>
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

export default React.memo(ManageProfile);
