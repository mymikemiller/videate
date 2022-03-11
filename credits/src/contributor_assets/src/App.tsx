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
  BrowserRouter as Router,
  Redirect,
  Route,
  Switch,
  useHistory,
  withRouter,
} from "react-router-dom";
import { createBrowserHistory } from "history";
import CreateProfile from "./components/CreateProfile";
import ManageProfile from "./components/ManageProfile";
import { emptyProfile, useAuthClient, useProfile } from "./hooks";
import { AuthClient } from "@dfinity/auth-client";
import { ActorSubclass } from "@dfinity/agent";
import { useEffect } from "react";
import { clear, remove } from "local-storage";
import { useState } from "react";
import RedirectManager from "./components/RedirectManager";
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
  updateProfile?: React.Dispatch<ProfileUpdate>;
}>({
  login: () => { },
  logout: () => { },
  profile: emptyProfile,
});

const App = () => {
  const history = createBrowserHistory();
  const {
    authClient,
    setAuthClient,
    isAuthenticated,
    setIsAuthenticated,
    login,
    logout,
    actor,
  } = useAuthClient();
  const identity = authClient?.getIdentity();
  const { profile, updateProfile } = useProfile({ identity });

  useEffect(() => {
    if (history.location.pathname === "/") return;

    if (actor) {
      if (!profile) {
        toast.loading("Checking for an existing contributor profile");
      }
      actor.read().then((result) => {
        if (history.location.pathname === "/") return;
        if ("ok" in result) {
          // Return if IC profile matches current
          if (compareProfiles(profile, result.ok)) {
            return;
          }
          toast.success("Updated contributor profile from IC");
          updateProfile(result.ok);
        } else {
          if ("NotAuthorized" in result.err) {
            // clear local delegation and log in
            toast.error("Your session expired. Please reauthenticate");
            logout();
          } else if ("NotFound" in result.err) {
            // User has deleted account
            remove("profile");
            if (profile) {
              toast.error("Contributor profile not found in IC. Please try creating again.");
            }
            updateProfile(undefined);
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
            updateProfile,
          }}
        >
          <Provider theme={defaultTheme}>
            <Router>
              <RedirectManager />
              <Header>
                <Route path="/manage">
                  <ActionButton id="logout" onPress={logout}>
                    Log out
                  </ActionButton>
                </Route>
                <Route path="/create">
                  <ActionButton id="logout" onPress={logout}>
                    Log out
                  </ActionButton>
                </Route>
                <h2>Videate</h2>
              </Header>
              <Main>
                <Flex maxWidth={700} margin="2rem auto" id="main-container">
                  <Switch>
                    <Route path="/" exact>
                      <Flex direction="column">
                        <Home />
                        <NotAuthenticated />
                      </Flex>
                    </Route>
                    <Route path="/manage" exact>
                      <ManageProfile />
                    </Route>
                    <Route path="/create" exact>
                      <CreateProfile />
                    </Route>
                  </Switch>
                </Flex>
              </Main>
            </Router>
          </Provider>
        </AppContext.Provider>
      </ErrorBoundary>
    </>
  );
};

export default App;
