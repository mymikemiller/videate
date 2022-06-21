import React, { useContext, useEffect, useState } from "react";
import { useParams } from "react-router";
import { useLocation, useSearchParams } from 'react-router-dom';
import styled from "styled-components";
import Loop from "../../assets/loop.svg";
import {
  Profile,
  _SERVICE as _CONTRIBUTOR_SERVICE,
} from "../../../declarations/contributor/contributor.did";
import {
  Feed,
  Media,
  _SERVICE as _SERVE_SERVICE,
} from "../../../declarations/serve/serve.did";
import { Dip721NFT } from "../../../declarations/Dip721NFT/Dip721NFT.did";
import { Actor, ActorSubclass } from "@dfinity/agent";
import {
  ActionButton,
  Button,
  Form,
  Heading,
  Icon,
} from "@adobe/react-spectrum";
import toast from "react-hot-toast";
import { AppContext } from "../App";
import { Principal } from "@dfinity/principal";

const Section = styled.section`
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
`;

interface NftFormState {
  feedKey: string,
  feed: Feed,
  media: Media,
  currentOwnerPrincipalText: string | undefined,
  currentOwnerName: string | undefined,
  // serveActor: ActorSubclass<_SERVE_SERVICE>;
};

const NftForm = () => {
  const { actor, login, authClient, profile } = useContext(AppContext);

  if (authClient == null || actor == null) {
    return (
      <Section>
        <h3>Please authenticate before buying an NFT</h3>
        <Button variant="cta" onPress={login}>
          Login with&nbsp;
          <Icon>
            <Loop />
          </Icon>
        </Button>
      </Section>
    );
  };

  const location = useLocation();
  const state = location.state as NftFormState;
  console.log("state:");
  console.dir(state);
  const [currentOwnerPrincipalText, setCurrentOwnerPrincipalText] = useState(state.currentOwnerPrincipalText);

  if (state.feed == undefined) {
    return (
      <Heading level={1}><>Feed "{state.feedKey}" not found. Check the URL for a valid feedKey.</></Heading>
    );
  };

  if (state.media == undefined) {
    return (
      <Heading level={1}><>Specified media not found in "{state.feedKey}" feed. Check the URL for a valid episodeGuid.</></Heading>
    );
  };

  // var currentOwnerName = "";

  // // Set currentOwnerName when the currentOwner changes
  // useEffect(() => {
  //   const setCurrentOwnerName = async (owner: string) => {
  //     console.log("setting current owner name:");
  //     console.dir(owner);
  //     console.log("typeof owner: " + typeof (owner));

  //     const ownerNameResult = await actor.getName(Principal.fromText(owner));
  //     console.log("ownerNameResult:");
  //     console.dir(ownerNameResult);
  //     if (ownerNameResult.length == 1) {
  //       console.log("had an element:");
  //       currentOwnerName = ownerNameResult[0];
  //       console.log(currentOwnerName);
  //     }
  //   }
  //   if (currentOwner != undefined) {
  //     console.log("setting current owner name using principal: ");
  //     console.dir(currentOwner);
  //     console.dir(currentOwner.toText());
  //     setCurrentOwnerName(currentOwner.toText());
  //   }
  // }, [currentOwner]);


  const handleSubmit = async () => {
    let result = await actor.buyNft(state.feedKey, state.media.uri); // For now, assume the media uri is the guid
    if ("Ok" in result) {
      toast.success("NFT successfully purchased!");
      setCurrentOwnerPrincipalText(authClient.getIdentity().getPrincipal().toText());
    } else {
      console.error("Error purchasing NFT:");
      console.dir(result);
      toast.error("Error purchasing NFT.");
    };
  };

  var currentOwnershipText = "No one has claimed this NFT yet!";
  if (currentOwnerPrincipalText != undefined) {
    // console.log(`typeof currentOwner: ${typeof currentOwner}`);
    // console.log(`currentOwner: ${currentOwner}`);
    // console.log(`state.currentOwner: ${state.currentOwner}`);
    // console.log(`user: ${authClient.getIdentity().getPrincipal()}`);
    // console.log("currentOwner.toText(): " + (currentOwner as Principal).toText());
    // console.log("authClient.getIdentity().getPrincipal().toText(): " + authClient.getIdentity().getPrincipal().toText());
    if (currentOwnerPrincipalText == authClient.getIdentity().getPrincipal().toText()) {
      currentOwnershipText = "You own this NFT!";
    } else {
      currentOwnershipText = `The NFT for this episode is currently owned by ${state.currentOwnerName}`;
    }
  }

  return (
    <section>
      <Heading level={1}><>NFT for {state.feed.title} episode "{state.media.title}"</></Heading>
      <Heading level={1}><>{currentOwnershipText}</></Heading>
      <Heading level={1}><>Buy this NFT?</></Heading>
      <Form
        onSubmit={(e) => {
          e.preventDefault();
          handleSubmit();
        }}>

        <ActionButton type="submit">Buy</ActionButton>
      </Form>
    </section>
  );
};

export default NftForm;
