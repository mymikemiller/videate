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
import Money from '../../assets/money.svg'

const NftFormContainer = styled.div`
  display: flex;
  flex-direction: column;
  padding-top: 1em;
`

const DarkCard = styled.div`
  display: flex;
  background-color: #2E2E2E;
  border: 1px solid #414141;
  padding: 0.75em 1em;
  border-radius: 5px;
  width: 85vw;
  margin: 2px auto;
  position: relative;
  font-weight: bold;
`

const Question = styled.div`
  display: flex;
  flex-direction: column;
  margin-top: 4em;
  align-items: center;
`

const MoneyImg = styled(Money)`
  height: 5em;
  width: 5em;
  margin-bottom: 1em;
`

const CallToAction = styled.button`
  width: 85vw;
  margin-top: 4em;
  background: linear-gradient(92.35deg, #21A8B0 11.82%, #5D27F5 180.4%, #5D27F5 180.4%);
  color: white;
  border: none;
  border-radius: 100px;
  padding: 0.75em 0;
  font-size: 20px;
  transform: translateX(3.5vw);
  box-shadow: 0px 2px 4px #146A70;
`

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
      currentOwnershipText = `Owned by ${state.currentOwnerName}`;
    }
  }

  const getPurchaseSection = () => {
    if (currentOwnerPrincipalText == authClient.getIdentity().getPrincipal().toText()) {
      return <></>
    } else {
      return <>
        <Question>
          <MoneyImg />
          Would you like to buy this NFT?
        </Question>
        <CallToAction onClick={() => handleSubmit()}>
          Purchase
        </CallToAction>
      </>
    }
  }

  return (
    // <section>
    //   <Heading level={1}><>NFT for {state.feed.title} episode "{state.media.title}"</></Heading>
    //   <Heading level={1}><>{currentOwnershipText}</></Heading>
    //   <Heading level={1}><>Buy this NFT?</></Heading>
    //   <Form
    //     onSubmit={(e) => {
    //       e.preventDefault();
    //       handleSubmit();
    //     }}>

    //     <ActionButton type="submit">Buy</ActionButton>
    //   </Form>
    // </section>
    <NftFormContainer>
      <DarkCard>
        <img src={state.feed.imageUrl} style={{ height: '6.5em', width: '6.5em', position: 'absolute', top: 10, left: 10, borderRadius: '5px 0 0 5px' }} />
        <div style={{ height: '5em', width: '22.5em' }} />
        This NFT is for the "{state.feed.title}" episode titled "{state.media.title}"
      </DarkCard>
      <div style={{ marginTop: '1em', fontWeight: 'bold', textAlign: 'center' }}>{currentOwnershipText}</div>
      {getPurchaseSection()}
    </NftFormContainer >
  );
};

export default NftForm;
