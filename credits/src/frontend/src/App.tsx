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
import PutFeedForm from "./components/PutFeedForm";
import toast, { Toaster } from "react-hot-toast";
import ErrorBoundary from "./components/ErrorBoundary";
import {
  Route,
  Routes,
  useNavigate,
  useLocation,
} from "react-router-dom";
import CreateProfile from "./components/CreateProfile";
import ManageProfile from "./components/ManageProfile";
import ManageFeeds from "./components/ManageFeeds";
import ListEpisodes from "./components/ListEpisodes";
import Loading from "./components/Loading";
import { emptyProfile, useAuthClient } from "./hooks";
import { AuthClient } from "@dfinity/auth-client";
import { ActorSubclass } from "@dfinity/agent";
import { useEffect } from "react";
import { compareProfiles } from "./utils";
import { _SERVICE, ProfileUpdate } from "../../declarations/serve/serve.did";
import Logout from '../assets/logout.svg'
import PutEpisodeForm from "./components/PutEpisodeForm";

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
  const location = useLocation();

  // Prevent the user from accidentally loading the raw version
  if (window.location.origin.includes(".raw.")) {
    return <h1>The raw version of the frontend is not supported. Remove '.raw' from the url.</h1>;
  };

  // At the page we first land on, record the URL the user was attempting to
  // load so we can navigate to it once we're logged in
  useEffect(() => {
    localStorage.setItem("landingPath", location.pathname + location.search);
  }, []);

  useEffect(() => {
    if (profile && actor) {
      if (compareProfiles(profile, emptyProfile)) {
        // Authenticated but no profile
        navigate('/create');
      }

      // We saved the landing URL when we first loaded, so navigate there now
      // that we're logged in and have a profile
      returnToLandingPage();
    };
  }, [profile]);

  const returnToLandingPage = () => {
    const landingPath = localStorage.getItem("landingPath");
    if (landingPath) {
      navigate(landingPath);
    } else {
      navigate("/");
    };
  };

  useEffect(() => {
    if (actor) {
      // We have a logged-in actor to work with, now fetch the profile
      var profileResult;
      (async () => {
        // Before we set the profile, we're first going to check if the user
        // clicked a link with a feedKey and update their profile if so (this
        // is so we can display their feeds in most-recently-interacted-with
        // order). We have to manually create a SearchParams object from the
        // stored URL since we haven't navigated there yet. We don't want to
        // navigate yet so we can stay at the loading screen until the profile
        // is fetched.
        var landingPath = localStorage.getItem("landingPath");
        if (landingPath) {
          // URLSearchParams wants only what's after the "?"
          var sanitizedLandingPath = landingPath;
          const splitLandingPath = landingPath.split("?");
          if (splitLandingPath.length > 1) {
            sanitizedLandingPath = splitLandingPath[1];
          }
          const searchParams = new URLSearchParams(sanitizedLandingPath);
          const feedKey = searchParams.get('feed');
          if (feedKey) {
            profileResult = await actor.addRequestedFeedKey(feedKey);
          }

          if (!profileResult || !("ok" in profileResult)) {
            // We either didn't store a landingPath, stored one that didn't
            // specify a feedKey, or were unsucessful in adding the requested
            // feedKey. Just load the profile manually.
            profileResult = await actor.readContributor();
          }

          if ("ok" in profileResult) {
            // Found contributor profile in IC. 
            setProfile(profileResult.ok); // This causes the profile useEffect above, which will redirect us appropriately
          } else {
            if ("NotAuthorized" in profileResult.err) {
              // Clear local delegation and log in
              toast.error("Your session expired. Please reauthenticate.");
              logout();
            } else if ("NotFound" in profileResult.err) {
              // Authenticated but no profile
              setProfile(undefined);
              navigate('/create');
            } else {
              toast.error("Error: " + Object.keys(profileResult.err)[0]);
            }
          }
        }
      })();
    };
  }, [actor]);

  if (!authClient) {
    return null;
  }

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
              {!isAuthenticated ? (
                <></>
              ) : (
                <Routes>
                  <Route path="/loading" element={
                    <span />
                  } />
                  <Route path="*" element={

                    <div style={{ display: 'flex', justifyContent: 'space-between', flexGrow: 1 }}>
                      <div id="menu">
                        <ul>
                          <li><a href="/">Subscribed Feeds</a>
                          </li>
                          <li><a href="/manageFeeds">Owned Feeds</a>
                          </li>
                        </ul>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'flex-end', flexGrow: 1 }}>
                        <h5>
                          {authClient.getIdentity().getPrincipal().toString()}
                        </h5>
                        <button onClick={logout} style={{ border: 'none', backgroundColor: 'transparent', cursor: 'pointer' }}>
                          <Logout />
                        </button>
                      </div>
                    </div>
                  }>
                  </Route>
                </Routes>
              )}
            </Header>
            <h2 style={{ textAlign: 'center', margin: 0 }}>Videate</h2>
            <Main>
              <Flex direction="column" justifyContent="start" maxWidth={700} id="main-container">
                {!isAuthenticated ? (
                  <Flex direction="column">
                    <Home />
                    <NotAuthenticated />
                  </Flex>
                ) : (
                  <Routes>
                    <Route path="/loading" element={<Loading />} />
                    <Route path="/" element={<ManageProfile />} />
                    <Route path="/manageProfile" element={<ManageProfile />} />
                    <Route path="/manageFeeds" element={<ManageFeeds />} />
                    <Route path="/create" element={<CreateProfile />} />
                    <Route path="/putFeed" element={<PutFeedForm />} />
                    <Route path="/putEpisode" element={<PutEpisodeForm />} />
                    <Route path="/listEpisodes" element={<ListEpisodes />} />
                    <Route path="/nft" element={<NftForm />} />
                  </Routes>
                )}
              </Flex>
            </Main>
          </Provider>
        </AppContext.Provider>
      </ErrorBoundary>
    </>
  );
};

export default App;
