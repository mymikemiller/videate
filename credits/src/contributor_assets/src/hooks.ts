import { ActorSubclass, Identity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { clear, get, remove, set } from "local-storage";
import { useState, useEffect } from "react";
import { canisterId, createActor } from "../../declarations/contributor";
import { ProfileUpdate, _SERVICE } from "../../declarations/contributor/contributor.did";

type UseAuthClientProps = {};
export function useAuthClient(props?: UseAuthClientProps) {
  const [authClient, setAuthClient] = useState<AuthClient>();
  const [actor, setActor] = useState<ActorSubclass<_SERVICE>>();
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);

  const login = () => {
    authClient?.login({
      identityProvider: process.env.II_URL,
      onSuccess: () => {
        initActor();
        setIsAuthenticated(true);
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
    clear();
    setIsAuthenticated(false);
    setActor(undefined);
  };

  useEffect(() => {
    AuthClient.create().then(async (client) => {
      const isAuthenticated = await client.isAuthenticated();
      setAuthClient(client);
      setIsAuthenticated(true);
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
  };
}

type UseProfileProps = {
  identity?: Identity;
};
export function useProfile(props: UseProfileProps) {
  const { identity } = props;
  const [profile, setProfile] = useState<ProfileUpdate>();

  const updateProfile = (profile: ProfileUpdate | undefined) => {
    if (profile) {
      set("profile", JSON.stringify(profile));
    } else remove("profile");
    setProfile(profile);
  };

  useEffect(() => {
    const stored = JSON.parse(get("profile")) as ProfileUpdate | undefined;
    if (stored) {
      setProfile(stored);
    }
  }, []);

  if (!identity) return { profile: emptyProfile, updateProfile };

  return { profile, updateProfile };
}

export const emptyProfile: ProfileUpdate = {
  bio: {
    name: [],
  },
};
