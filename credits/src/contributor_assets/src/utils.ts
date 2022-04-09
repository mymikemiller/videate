import { ActorSubclass } from "@dfinity/agent";
import toast from "react-hot-toast";
import { Profile, ProfileUpdate, _SERVICE } from "../../declarations/contributor/contributor.did";

export function compareProfiles(p1: any | null, p2: any) {
  if (!p1) return false;

  for (const key in p1.bio) {
    if (Object.prototype.hasOwnProperty.call(p1.bio, key)) {
      const element = p1.bio[key];
      if (element[0] !== p2.bio[key][0]) return false;
    }
  }
  return true;
}

export async function pushProfileUpdate(actor: ActorSubclass<_SERVICE>, profileUpdate: ProfileUpdate): Promise<Profile | undefined> {
  const result = await actor!.update(profileUpdate);
  if ("ok" in result) {
    const profileResponse = await actor.read();
    if ("ok" in profileResponse) {
      return profileResponse.ok;
    } else {
      console.error(profileResponse.err);
      toast.error("Failed to read profile from IC");
      return;
    }
  } else {
    console.error(result.err);
    toast.error("Failed to save update to IC");
    return;
  }
};
