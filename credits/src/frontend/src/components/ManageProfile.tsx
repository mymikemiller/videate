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
  const [satPerUsd, setSatPerUsd] = useState(4_000); // This value is an estimate. todo: fetch actual value
  const [distributionElement, setDistributionElement] = useState(<></>);
  const [satoshiBalance, setSatoshiBalance] = useState<BigInt | undefined>(undefined);
  const [balanceDisplay, setBalanceDisplay] = useState("Loading...");
  const { authClient, actor, profile, setProfile } = useContext(AppContext);
  const navigate = useNavigate();

  useEffect(() => {
    (async () => {
      // todo: fetch current value for Satoshi per USD and call setSatPerUsd()
      await updateBalance();
    })();
  }, [actor]);

  // Update the balance display when the balance is changed
  useEffect(() => {
    if (actor !== undefined && satoshiBalance != undefined) {
      (async () => {
        const _usdBalance = Number(satoshiBalance) / satPerUsd;
        setBalanceDisplay("$" + _usdBalance.toFixed(2) + " (" + satoshiBalance + " ckSat)");
      })();
    }
  }, [satoshiBalance]);

  const updateBalance = async () => {
    const balanceResult = await actor?.getBalance();
    if (balanceResult !== undefined && "ok" in balanceResult) {
      const balance = balanceResult.ok;
      setSatoshiBalance(balance);
    };
  }

  const performDistribution = async (distributionAmountSatoshi: bigint) => {
    if (actor == undefined) {
      "Actor undefined";
      return;
    }
    setDistributionElement(<Text>Please wait...</Text>);

    (async () => {
      const distributionResult = await actor!.performDistribution(distributionAmountSatoshi);

      if (distributionResult !== undefined && "ok" in distributionResult) {
        const distributionAmountsSatoshi = distributionResult.ok;
        const listElements = [];
        for (let index in distributionAmountsSatoshi) {
          const values = distributionAmountsSatoshi[index];
          const principal = values[0];
          const name = values[1] ? values[1] : "Contributor not found";
          const satoshiAmount = values[2];
          const usdAmount = Number(satoshiAmount / BigInt(satPerUsd));
          const usdAmountAsString = usdAmount.toFixed(2);
          listElements.push(
            <li key={index} style={{ listStyleType: 'none', marginBottom: '1em' }} >
              <Text>${usdAmountAsString} ({satoshiAmount.toString()} ckSat) sent to {name}</Text>
            </li>
          );
        };

        if (listElements.length == 0) {
          setDistributionElement(<Text>No videos watched this month. No distribution performed.</Text>);
        } else {
          const element =
            <ul style={{ padding: 0 }} >
              {listElements}
            </ul>
          setDistributionElement(<div>{element}</div>);
        }
        setBalanceDisplay("Loading...");
        await updateBalance();
      } else {
        const element =
          <Text>Error: {Object.values(distributionResult.err)}</Text>
        setDistributionElement(<div>{element}</div>);
      }
    })();
  }

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
          <Text>Current balance: {balanceDisplay}</Text>
          <div>
            <ActionButton onPress={() => {
              performDistribution(BigInt(10 * satPerUsd));
            }}>
              <Text>Give $10 ({10 * satPerUsd} ckSat)</Text>
            </ActionButton>
          </div>
          {distributionElement}
        </section>
      )
      }
    </>
  );
}

export default ManageProfile;
