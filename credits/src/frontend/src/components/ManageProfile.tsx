import {
  ActionButton,
  ButtonGroup,
  Heading,
  Text,
} from "@adobe/react-spectrum";
import Cancel from "@spectrum-icons/workflow/Cancel";
import Delete from "@spectrum-icons/workflow/Delete";
import Edit from "@spectrum-icons/workflow/Edit";
import React, { useEffect, useState } from "react";
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
import FeedLink, { Mode as FeedLinkMode } from "./FeedLink";
import ProfileForm from "./ProfileForm";
import { _SERVICE as _SERVE_SERVICE } from "../../../declarations/serve/serve.did";
import { Principal } from "@dfinity/principal";
import { Input, Label } from "./styles/styles";

function ManageProfile() {
  const [isEditing, setIsEditing] = useState(false);
  const [distributionSimAmount, setDistributionSimAmount] = useState(0.0);
  const [distributionSimElement, setDistributionSimElement] = useState(<></>);
  const { authClient, actor, profile, setProfile } = useContext(AppContext);
  const navigate = useNavigate();

  useEffect(() => {
    if (distributionSimAmount == 0.0) {
      setDistributionSimElement(<></>);
      return;
    };

    setDistributionSimElement(<Text>Please wait...</Text>);

    (async () => {
      const distributionAmounts = await actor!.getDistribution(distributionSimAmount);

      const listElements = [];
      for (let index in distributionAmounts) {
        const values = distributionAmounts[index];
        const principal = values[0];
        const name = values[1] ? values[1] : "Contributor not found";
        const amount = values[2];
        const amountAsString = (Math.round(amount * 100) / 100).toFixed(2);
        listElements.push(
          <li key={index} style={{ listStyleType: 'none', marginBottom: '1em' }} >
            <Text>${amountAsString}: {name}</Text>
          </li>
        );
      };

      const element =
        <ul style={{ padding: 0 }} >
          {listElements}
        </ul>

      setDistributionSimElement(<div>{element}</div>);
    })();

  }, [distributionSimAmount]);

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
        navigate('/');
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

  if (actor == undefined) {
    return null;
  }

  return (
    <>
      {isEditing ? (
        <section key={String(isEditing)}>
          <Heading level={2}>Editing Profile</Heading>
          <Text>Principal: {authClient!.getIdentity().getPrincipal().toString()}</Text>
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

          <ButtonGroup>
            <ActionButton onPress={() => setIsEditing(true)}>
              <Edit />
              <Text>Edit Profile</Text>
            </ActionButton>
            <ActionButton onPress={deleteProfile}>
              <Delete /> <Text>Delete Profile</Text>
            </ActionButton>
          </ButtonGroup>
          <Heading level={2}>
            Hello
            {fallbackDisplayName[0] ? `, ${fallbackDisplayName[0]}` : ""}. Here are the feeds you subscribe to:
          </Heading>
          {feedKeys.length == 0 && <Text>No feed keys found. Please click the Videate link in the shownotes to populate.</Text>}
          <ul style={{ padding: 0 }} >
            {feedKeys.map((feedKey, index) => {
              return (
                <li key={feedKey} style={{ listStyleType: 'none', marginBottom: '1em' }} >
                  <FeedLink mode={FeedLinkMode.Copy} feedKey={feedKey} />
                </li>
              )
            })}
          </ul>
          <div>
            <ActionButton onPress={() => {
              setDistributionSimAmount(0);
              setDistributionSimAmount(10.0);
            }}>
              <Text>Simulate $10 Gift</Text>
            </ActionButton>
          </div>
          {distributionSimElement}
        </section>
      )
      }
    </>
  );
}

export default ManageProfile;
