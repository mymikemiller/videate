import { ActorSubclass } from "@dfinity/agent";
import toast from "react-hot-toast";
import { Feed, Profile, ProfileUpdate, AddFeedResult, _SERVICE, Media } from "../../declarations/serve/serve.did";

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
  const result = await actor!.updateContributor(profileUpdate);
  if ("ok" in result) {
    const profileResponse = await actor.readContributor();
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

export async function pushNewFeed(actor: ActorSubclass<_SERVICE>, feed: Feed, feedKey: string): Promise<AddFeedResult> {
  return actor!.addFeed(feedKey, feed);
};

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


export async function getMedia(actor: ActorSubclass<_SERVICE>, feedKey: string, episodeGuid: string): Promise<{ feed: Feed | undefined; media: Media | undefined; }> {
  const feedResult: [Feed] | [] = await actor.getFeed(feedKey);
  const feed: Feed = feedResult[0]!;
  if (feed == undefined) {
    return { feed: undefined, media: undefined };
  };
  // For now, assume the episodeGuid will always match the media's uri
  const media: Media | undefined = feed.mediaList.find((media) => media.uri == episodeGuid);
  return { feed, media };
};
