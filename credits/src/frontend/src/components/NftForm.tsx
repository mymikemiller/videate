import React, { useContext, useEffect, useState } from "react";
import { useParams } from "react-router";
import { useLocation, useSearchParams } from 'react-router-dom';
import styled from "styled-components";
import Loop from "../../assets/loop.svg";
import {
  Feed,
  Media,
  OwnerResult,
  _SERVICE as _SERVE_SERVICE,
} from "../../../declarations/serve/serve.did";
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

  const [currentOwner, setCurrentOwner] = useState<Principal>();
  const [currentOwnerName, setCurrentOwnerName] = useState<string>();
  const [currentOwnershipText, setCurrentOwnershipText] = useState<string>();

  useEffect(() => {
    updateCurrentOwnershipMessage();
  }, [currentOwnerName, currentOwner]);

  useEffect(() => {
    setCurrentOwnerInfo();
  }, []);

  const setCurrentOwnerInfo = async () => {
    // Find the current owner name if there is one
    if (state.media != undefined && state.media.nftTokenId.length == 1) {
      const nftTokenId = state.media.nftTokenId[0]!;
      const ownerResult: OwnerResult = await actor.ownerOfDip721(nftTokenId);
      if ("Ok" in ownerResult) {
        const owner = ownerResult.Ok;
        setCurrentOwner(owner);
        const currentOwnerNameResult = await actor.getContributorName(owner!);
        if (currentOwnerNameResult.length == 1) {
          setCurrentOwnerName(currentOwnerNameResult[0]);
        };
      };
    };
  };

  const updateCurrentOwnershipMessage = () => {
    if (currentOwner == undefined) {
      setCurrentOwnershipText("No one has claimed this NFT yet!");
    } else {
      if (currentOwner.toString() == authClient.getIdentity().getPrincipal().toString()) {
        setCurrentOwnershipText("You own this NFT!!!!");
      } else {
        if (currentOwnerName == undefined) {
          setCurrentOwnershipText(`Fetching NFT owner name...`);
        } else {
          setCurrentOwnershipText(`Owned by ${currentOwnerName}`);
        }
      }
    }
  }

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

  const handleSubmit = async () => {
    let userPrincipal = authClient.getIdentity().getPrincipal();
    let result = await actor.buyNft(state.feedKey, state.media);
    if ("Ok" in result) {
      toast.success("NFT successfully purchased!");
      setCurrentOwner(userPrincipal);
    } else {
      console.error(result);
      toast.error("Error purchasing NFT.");
    };
  };

  const getPurchaseSection = () => {
    if (currentOwner?.toString() == authClient.getIdentity().getPrincipal().toString()) {
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
