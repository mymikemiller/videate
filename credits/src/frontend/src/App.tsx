import * as React from "react";
import {
  Provider,
  defaultTheme,
  Flex,
} from "@adobe/react-spectrum";
import styled from "styled-components";
import NotAuthenticated from "./components/NotAuthenticated";
import Home from "./components/Home";
import NftForm from "./components/NftForm";
import toast, { Toaster } from "react-hot-toast";
import ErrorBoundary from "./components/ErrorBoundary";
import {
  Outlet,
  Route,
  Routes,
  useNavigate,
  useSearchParams,
} from "react-router-dom";
import CreateProfile from "./components/CreateProfile";
import ManageProfile from "./components/ManageProfile";
import Loading from "./components/Loading";
import { emptyProfile, useAuthClient } from "./hooks";
import { AuthClient } from "@dfinity/auth-client";
import { ActorSubclass } from "@dfinity/agent";
import { useEffect, useState } from "react";
import { compareProfiles } from "./utils";
import { _SERVICE, Feed, Media, OwnerResult, ProfileUpdate } from "../../declarations/serve/serve.did";
import Logout from '../assets/logout.svg'

const Header = styled.header`
  position: relative;
  padding: 1rem;
  display: flex;
  justify-content: center;
  h1 {
    margin-top: 0;
  }
  #logout {
    position: absolute;
    right: 0.5rem;
    top: 0.5rem;
  }
`;

const Main = styled.main`
  display: flex;
  flex-direction: column;
  padding: 0 1rem;
  position: relative;
`;

export const AppContext = React.createContext<{
  authClient?: AuthClient;
  setAuthClient?: React.Dispatch<AuthClient>;
  isAuthenticated?: boolean;
  setIsAuthenticated?: React.Dispatch<React.SetStateAction<boolean>>;
  login: () => void;
  logout: () => void;
  actor?: ActorSubclass<_SERVICE>;
  profile?: ProfileUpdate;
  setProfile: React.Dispatch<ProfileUpdate>;
}>({
  login: () => { },
  logout: () => { },
  profile: emptyProfile,
  setProfile: () => { },
});

// Stores the specified search param value in local storage if it was, indeed,
// in the search params list. If not, removes the existing value in local
// storage if there is one.
const storeOrRemoveSearchParam = (searchParams: URLSearchParams, paramName: string) => {
  const value = searchParams.get(paramName);
  if (value) {
    localStorage.setItem(paramName, value);
  } else {
    localStorage.removeItem(paramName);
  }
};

const getMedia = async (actor: ActorSubclass<_SERVICE>, feedKey: string, episodeGuid: string): Promise<{ feed: Feed | undefined; media: Media | undefined; }> => {
  const feedResult: [Feed] | [] = await actor.getFeed(feedKey);
  const feed: Feed = feedResult[0]!;
  if (feed == undefined) {
    return { feed: undefined, media: undefined };
  };
  // For now, assume the episodeGuid will always match the media's uri
  const media: Media | undefined = feed.mediaList.find((media) => media.uri == episodeGuid);
  return { feed, media };
};

const App = () => {
  const {
    authClient,
    setAuthClient,
    isAuthenticated,
    setIsAuthenticated,
    login,
    logout,
    actor,
    profile,
    setProfile,
  } = useAuthClient();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  // At the page we first land on, record the key from the search params so we
  // know which rss feed and episode the user was watching when they clicked
  // the link to launch this site.
  useEffect(() => {
    storeOrRemoveSearchParam(searchParams, "feedKey");
    storeOrRemoveSearchParam(searchParams, "episodeGuid");
  }, []);

  useEffect(() => {
    console.log("either profile or actor was set");
    console.log("profile:");
    console.dir(profile);
    console.log("actor:");
    console.dir(actor);
    if (profile && actor) {
      console.log("profile and actor are both set")
      if (compareProfiles(profile, emptyProfile)) {
        // Authenticated but no profile
        navigate('/create');
      }

      const feedKey = localStorage.getItem('feedKey');
      if (feedKey) {
        localStorage.removeItem("feedKey");

        actor.addRequestedFeedKey(feedKey).then(async (result) => {
          if ("ok" in result) {
            setProfile(result.ok);

            // Go to the NFT page if the original link contained an
            // episodeGuid, otherwise go to profile management page
            const episodeGuid = localStorage.getItem('episodeGuid');
            if (episodeGuid) {
              localStorage.removeItem("episodeGuid");

              // Note that feed and media might come back undefined if the feed
              // isn't found
              const { feed, media } = await getMedia(actor, feedKey, episodeGuid);

              navigate('/nft', { state: { feedKey, feed, media } });
            } else {
              navigate('/manage');
            }
          }
        });
      } else {
        // Just send the user to their management page even without a feedKey
        // to add
        navigate('/manage');
      };
    };
  }, [profile]);

  useEffect(() => {
    if (actor) {
      actor.readContributor().then((result) => {
        if ("ok" in result) {
          // Found contributor profile in IC. 
          setProfile(result.ok); // This causes the profile useEffect above, which will redirect us appropriately
        } else {
          if ("NotAuthorized" in result.err) {
            // Clear local delegation and log in
            toast.error("Your session expired. Please reauthenticate.");
            logout();
          } else if ("NotFound" in result.err) {
            // User has deleted account
            if (profile) {
              toast.error("Contributor profile not found. Please try creating again.");
            }
            // Authenticated but no profile
            setProfile(undefined);
            navigate('/create');
          } else {
            toast.error("Error: " + Object.keys(result.err)[0]);
          }
        }
      });
    }
  }, [actor]);

  if (!authClient) return null;

  return (
    <>
      <Toaster
        toastOptions={{
          duration: 5000,
          position: "bottom-center",
        }}
      />
      <ErrorBoundary>
        <AppContext.Provider
          value={{
            authClient,
            setAuthClient,
            isAuthenticated,
            setIsAuthenticated,
            login,
            logout,
            actor,
            profile,
            setProfile
          }}
        >
          <Provider theme={defaultTheme}>
            <Header>
              <Routes>
                <Route path="/" element={
                  <span />
                } />
                <Route path="/loading" element={
                  <span />
                } />
                <Route path="/nft" element={
                  <h5>
                    {authClient.getIdentity().getPrincipal().toString()}
                  </h5>} />
                <Route path="*" element={isAuthenticated ? (
                  <div style={{ display: 'flex', justifyContent: 'flex-end', flexGrow: 1 }}>
                    <h5>
                      {authClient.getIdentity().getPrincipal().toString()}
                    </h5>
                    <button onClick={logout} style={{ border: 'none', backgroundColor: 'transparent', cursor: 'pointer' }}>
                      <Logout />
                    </button>
                  </div>
                ) : <span />
                }>
                </Route>
                {/* <Route path="/create" element={
                  <ActionButton id="logout" onPress={logout}>
                    Log out
                  </ActionButton>
                }>
                </Route>
                <Route path="/nft" element={
                  <ActionButton id="logout" onPress={logout}>
                    Log out
                  </ActionButton>
                } /> */}
              </Routes>
            </Header>
            <h2 style={{ textAlign: 'center', margin: 0 }}>Videate</h2>
            <Main>
              <Flex maxWidth={700} id="main-container">
                <Routes>
                  <Route path="/loading" element={<Loading />} />
                  <Route path="/" element={
                    <Flex direction="column">
                      <Home />
                      <NotAuthenticated />
                    </Flex>
                  } />
                  <Route path="/manage" element={<ManageProfile />} />
                  <Route path="/create" element={<CreateProfile />} />
                  <Route path="/nft" element={<NftForm />} />
                </Routes>
              </Flex>
            </Main>
          </Provider>
        </AppContext.Provider>
      </ErrorBoundary>
    </>
  );
};

export default App;
