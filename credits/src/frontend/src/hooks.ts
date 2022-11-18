import { ActorSubclass } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { useState, useEffect } from "react";
import { canisterId, createActor } from "../../declarations/serve";
import { ProfileUpdate, _SERVICE } from "../../declarations/serve/serve.did";
import { useNavigate } from "react-router-dom";

type UseAuthClientProps = {};
export function useAuthClient(props?: UseAuthClientProps) {
  const [authClient, setAuthClient] = useState<AuthClient>();
  const [actor, setActor] = useState<ActorSubclass<_SERVICE>>();
  const [profile, setProfile] = useState<ProfileUpdate>();
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const navigate = useNavigate();

  const ii_url = process.env.II_URL;

  const login = async () => {
    const alreadyAuthenticated = await authClient?.isAuthenticated();
    if (alreadyAuthenticated) {
      setIsAuthenticated(true);
      navigate('/loading');
    } else {
      authClient?.login({
        identityProvider: ii_url,
        onSuccess: () => {
          setIsAuthenticated(true);
          navigate('/loading');
        },
      });
    }
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
    authClient?.logout({ returnTo: "/" });
  };

  useEffect(() => {
    if (authClient == null) {
      AuthClient.create().then(async (client) => {
        setAuthClient(client);
      });
    }
  }, []);

  useEffect(() => {
    if (authClient != null) {
      (async () => {
        const authenticated = await authClient?.isAuthenticated();
        if (authenticated) {
          setIsAuthenticated(true);
        }
      })();
    }
  }, [authClient]);

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
  feedKeys: [],
  ownedFeedKeys: [],
  downloads: [],
};
