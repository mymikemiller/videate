import React, { useContext, useEffect, useState } from "react";
import { useLocation, useSearchParams } from 'react-router-dom';
import styled from "styled-components";
import { getMedia } from "../utils";
import {
  Feed,
  Media,
  OwnerResult,
  _SERVICE as _SERVE_SERVICE,
} from "../../../declarations/serve/serve.did";
import {
  Heading,
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

const NftForm = (): JSX.Element => {
  const { actor, authClient } = useContext(AppContext);
  const [searchParams] = useSearchParams();
  const [feedKey, setFeedKey] = useState(searchParams.get('feedKey'));
  const [episodeGuid, setEpisodeGuid] = useState(searchParams.get('episodeGuid'));
  const [feed, setFeed] = useState<Feed | null | undefined>(null);
  const [media, setMedia] = useState<Media | null | undefined>(null);
  const [currentOwner, setCurrentOwner] = useState<Principal>();
  const [currentOwnerName, setCurrentOwnerName] = useState<string>();
  const [currentOwnershipText, setCurrentOwnershipText] = useState<string>();

  const setCurrentOwnerInfo = async () => {
    if (actor) {
      // Find the current owner name if there is one
      if (media != undefined && media.nftTokenId.length == 1) {
        const nftTokenId = media.nftTokenId[0]!;
        const ownerResult: OwnerResult = await actor.ownerOfDip721(nftTokenId);
        if ("ok" in ownerResult) {
          const owner = ownerResult.ok;
          setCurrentOwner(owner);
          const currentOwnerNameResult = await actor.getContributorName(owner!);
          if (currentOwnerNameResult.length == 1) {
            setCurrentOwnerName(currentOwnerNameResult[0]);
          };
        };
      }
    }
  };

  const updateCurrentOwnershipMessage = () => {
    if (authClient) {
      if (currentOwner == undefined) {
        setCurrentOwnershipText("No one has claimed this NFT yet!");
      } else {
        if (currentOwner.toString() == authClient.getIdentity().getPrincipal().toString()) {
          setCurrentOwnershipText("You own this NFT!!!!");
        } else {
          if (currentOwnerName == undefined) {
            setCurrentOwnershipText(`Fetching NFT owner name...`);
          } else {
            // todo: set the price at $1 higher than the current owner
            // purchased it for
            setCurrentOwnershipText(`Owned by ${currentOwnerName}`);
          }
        }
      }
    }
  }

  useEffect(() => {
    updateCurrentOwnershipMessage();
  }, [currentOwnerName, currentOwner]);

  useEffect(() => {
    setCurrentOwnerInfo();
  }, [media]);

  // We should have a logged-in actor before navigating here
  if (authClient == null || actor == null) {
    return (<></>);
  };

  if (feedKey == null || episodeGuid == null) {
    return (<h1>URL must specify feedKey and episodeGuid query params</h1>);
  };

  const fetchMedia = async () => {
    const { feed, media } = await getMedia(actor, feedKey, episodeGuid);
    // Note that feed and media might come back undefined if the feed isn't
    // found
    setFeed(feed);
    setMedia(media);
  };
  if (feed == null || media == null) {
    fetchMedia();
  };

  if (feed == null || media == null) {
    return (<h1>Retrieving NFT for requested episode...</h1>);
  };

  if (feed == undefined) {
    return (
      <Heading level={1}><>Feed "{feedKey}" not found. Check the URL for a valid feedKey.</></Heading>
    );
  };

  if (media == undefined) {
    return (
      <Heading level={1}><>Specified media not found in "{feedKey}" feed. Check the URL for a valid episodeGuid.</></Heading>
    );
  };

  const handleSubmit = async () => {
    let userPrincipal = authClient.getIdentity().getPrincipal();
    let result = await actor.buyNft(feedKey, media);
    if ("ok" in result) {
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
        <img src={feed.imageUrl} style={{ height: '6.5em', width: '6.5em', position: 'absolute', top: 10, left: 10, borderRadius: '5px 0 0 5px' }} />
        <div style={{ height: '5em', width: '22.5em' }} />
        This NFT is for the "{feed.title}" episode titled "{media.title}"
      </DarkCard>
      {/* todo: display a list of all the previous owners and how much they bought it for */}
      <div style={{ marginTop: '1em', fontWeight: 'bold', textAlign: 'center' }}>{currentOwnershipText}</div>
      {getPurchaseSection()}
    </NftFormContainer >
  );
};

export default NftForm;
