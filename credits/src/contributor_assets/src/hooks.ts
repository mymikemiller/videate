import { ActorSubclass } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { useState, useEffect } from "react";
import { canisterId, createActor } from "../../declarations/contributor";
import { ProfileUpdate, _SERVICE } from "../../declarations/contributor/contributor.did";
import { useNavigate } from "react-router-dom";
import { compareProfiles } from "./utils";

type UseAuthClientProps = {};
export function useAuthClient(props?: UseAuthClientProps) {
  const [authClient, setAuthClient] = useState<AuthClient>();
  const [actor, setActor] = useState<ActorSubclass<_SERVICE>>();
  const [profile, setProfile] = useState<ProfileUpdate>();
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const navigate = useNavigate();

  const login = () => {
    authClient?.login({
      identityProvider: process.env.II_URL,
      onSuccess: () => {
        setIsAuthenticated(true);

        if (!profile || profile == undefined || compareProfiles(profile, emptyProfile)) {
          // Authenticated but no profile
          navigate('/create');
        } else {
          // Logged in with profile
          navigate('/manage');
        }
      },
    });
  };

  const initActor = () => {
    const actor = createActor(canisterId as string, {
      agentOptions: {
        identity: authClient?.getIdentity(),
      },
    });
    setActor(actor);
  };

  const logout = () => {
    setIsAuthenticated(false);
    setActor(undefined);
    navigate('/');
  };

  useEffect(() => {
    AuthClient.create().then(async (client) => {
      // Call client.isAuthenticated for side effect purposes
      await client.isAuthenticated();
      setAuthClient(client);
    });
  }, []);

  useEffect(() => {
    if (isAuthenticated) initActor();
  }, [isAuthenticated]);

  return {
    authClient,
    setAuthClient,
    isAuthenticated,
    setIsAuthenticated,
    login,
    logout,
    actor,
    profile,
    setProfile,
  };
}

export const emptyProfile: ProfileUpdate = {
  bio: {
    name: [],
  },
  feedUrls: [],
};
