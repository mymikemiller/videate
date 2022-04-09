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
  Profile,
  ProfileUpdate,
  _SERVICE,
} from "../../../declarations/contributor/contributor.did";
import { AppContext } from "../App";
import { emptyProfile } from "../hooks";
import { pushProfileUpdate } from "../utils";
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
    console.log('There is no profile, so returning null for ManageProfile component');
    return null;
  }

  const { name } = profile.bio;
  const { feedUrls } = profile;

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
          {feedUrls.length == 0 && <Text>No feed URLs found. Please click the Videate link in the shownotes to populate.</Text>}
          <ul>
            {feedUrls.map((feedUrl, index) => (
              <li key={index}>
                <p>{feedUrl}</p>
              </li>
            ))}
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

export default React.memo(ManageProfile);
