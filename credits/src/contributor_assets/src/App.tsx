import * as React from "react";
import {
  Provider,
  defaultTheme,
  Flex,
  ActionButton,
} from "@adobe/react-spectrum";
import styled from "styled-components";
import NotAuthenticated from "./components/NotAuthenticated";
import Home from "./components/Home";
import { _SERVICE, ProfileUpdate } from "../../declarations/contributor/contributor.did";
import toast, { Toaster } from "react-hot-toast";
import ErrorBoundary from "./components/ErrorBoundary";
import {
  Route,
  Routes,
  useNavigate,
  useSearchParams,
} from "react-router-dom";
import { createBrowserHistory } from "history";
import CreateProfile from "./components/CreateProfile";
import ManageProfile from "./components/ManageProfile";
import { emptyProfile, useAuthClient } from "./hooks";
import { AuthClient } from "@dfinity/auth-client";
import { ActorSubclass } from "@dfinity/agent";
import { useEffect } from "react";

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
  setProfile?: React.Dispatch<ProfileUpdate>;
}>({
  login: () => { },
  logout: () => { },
  profile: emptyProfile,
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
  const [searchParams] = useSearchParams();

  // At the page we first land on, record the URL from the search params so we
  // know which rss feed the user was watching when they clicked the link to
  // launch this site.
  useEffect(() => {
    const feedUrl = searchParams.get("feedUrl");
    if (feedUrl) {
      console.log(`Found incoming feed url in searchParams: ${feedUrl}`);
      localStorage.setItem('incomingFeedUrl', feedUrl);
    } else {
      console.error('No incoming feed url was found in searchParams');
      localStorage.removeItem('incomingFeedUrl');
    }
  }, []);

  useEffect(() => {
    if (profile) {
      const feedUrl = localStorage.getItem('incomingFeedUrl');
      console.log(`Adding feedUrl to profile: ${feedUrl}`);
    }
  }, [profile]);

  useEffect(() => {
    if (actor) {
      if (!profile) {
        toast.loading("Checking for an existing contributor profile");
      }
      actor.read().then((result) => {
        if ("ok" in result) {
          toast.success("Found contributor profile in IC. Loading Home Page.");
          setProfile(result.ok);
          navigate('/manage');
        } else {
          if ("NotAuthorized" in result.err) {
            // clear local delegation and log in
            toast.error("Your session expired. Please reauthenticate.");
            logout();
          } else if ("NotFound" in result.err) {
            // User has deleted account
            if (profile) {
              toast.error("Contributor profile not found in IC. Please try creating again.");
            }
            setProfile(undefined);
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
                }>
                </Route>
                <Route path="/manage" element={
                  <ActionButton id="logout" onPress={logout}>
                    Log out
                  </ActionButton>
                }>
                </Route>
                <Route path="/create" element={
                  <ActionButton id="logout" onPress={logout}>
                    Log out
                  </ActionButton>
                }>
                </Route>
              </Routes>
              <h2>Videate</h2>
            </Header>
            <Main>
              <Flex maxWidth={700} margin="2rem auto" id="main-container">
                <Routes>
                  <Route path="/" element={
                    <Flex direction="column">
                      <Home />
                      <NotAuthenticated />
                    </Flex>
                  }>
                  </Route>
                  <Route path="/manage" element={
                    <ManageProfile />
                  } >
                  </Route>
                  <Route path="/create" element={
                    <CreateProfile />
                  }>
                  </Route>
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
