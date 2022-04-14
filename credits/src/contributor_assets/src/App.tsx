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
import CreateProfile from "./components/CreateProfile";
import ManageProfile from "./components/ManageProfile";
import Loading from "./components/Loading";
import { emptyProfile, useAuthClient } from "./hooks";
import { AuthClient } from "@dfinity/auth-client";
import { ActorSubclass } from "@dfinity/agent";
import { useEffect } from "react";
import { compareProfiles } from "./utils";

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
  const [searchParams] = useSearchParams();

  // At the page we first land on, record the key from the search params so we
  // know which rss feed the user was watching when they clicked the link to
  // launch this site.
  useEffect(() => {
    const feedKey = searchParams.get("feedKey");
    if (feedKey) {
      localStorage.setItem('incomingFeedKey', feedKey);
    } else {
      localStorage.removeItem('incomingFeedKey');
    }
  }, []);

  useEffect(() => {
    if (profile && actor) {
      const incomingFeedKey = localStorage.getItem('incomingFeedKey');
      if (incomingFeedKey) {
        console.log("adding feedKey: " + incomingFeedKey);
        actor.addFeedKey(incomingFeedKey).then((result) => {
          if ("ok" in result) {
            setProfile(result.ok);
            navigate('/manage');
          } else {
            toast.error("Error: " + Object.keys(result.err)[0]);
          };
        });
        localStorage.removeItem("incomingFeedKey");
      };
    };
  }, [profile]);

  useEffect(() => {
    if (actor) {
      actor.read().then((result) => {
        if ("ok" in result) {
          // Found contributor profile in IC. Load Home Page.
          setProfile(result.ok);
          if (compareProfiles(result.ok, emptyProfile)) {
            // Authenticated but no profile
            navigate('/create');
          } else {
            // Logged in with profile
            navigate('/manage');
          }
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
                  <Route path="/loading" element={<Loading />} />
                  <Route path="/" element={
                    <Flex direction="column">
                      <Home />
                      <NotAuthenticated />
                    </Flex>
                  } />
                  <Route path="/manage" element={<ManageProfile />} />
                  <Route path="/create" element={<CreateProfile />} />
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
