import Result "mo:base/Result";
import Buffer "mo:base/Buffer";

module {
  // Used to store the contents of the Credits canister in stable types
  // between upgrades
  public type StableCredits = {
    mediaEntries : [Media];
    episodeEntries : [Episode];
    feedEntries : [(FeedKey, Feed)];
    custodianEntries : [Principal];
  };

  // Represents the platform where the source media was originally released,
  // e.g. youtube
  public type Platform = {
    // The Uri to the platform's main page, e.g. 'http://www.youtube.com'
    uri : Text;

    // An id unique among all platforms, e.g. 'youtube'
    id : Text;
  };

  // Represents the original source of media, e.g. a video's page on YouTube
  public type Source = {
    // The source platform, e.g. youtube
    platform : Platform;

    // The Uri where the media can be accessed on the source platform
    uri : Text;

    // An id unique among all media on the source platform, likely part of
    // the uri
    id : Text;

    // The date the media was released on the source platform. Example:
    // 1970-01-01T00:00:00.000Z
    releaseDate : Text;
  };

  // Something or someone that the creation of Media depends on
  public type Resource = {
    // Another Episode that was integral to the creation of the associated Media,
    // for example: a video that was used as part of a compilation video
    #episode : {
      feedKey : Text;
      episodeId : EpisodeID;
    };

    // An individual that was integral to the creation of the associated Media,
    // for example: the editor of a video
    #individual : Principal;
  };

  public type WeightedResource = {
    // The relative "weight" of this Resource. This dermines how much of a
    // Media's income should go to this Resource. The portion that goes to this
    // Resource is calculated by dividing this weight by the sum of all weights
    // for the given Episode.
    weight : Nat;

    // The Resource that gets paid when the associated Media earns income
    resource : Resource;
  };

  public type MediaData = {
    // The source of the media, which contains information about how to
    // access the media on the platform on which it was originally released
    source : Source;

    // All resources that this Media depended on for its creation. This
    // determines who gets paid, and how much, when this Media earns income.
    resources : [WeightedResource];

    // The duration of the media in microseconds
    durationInMicroseconds : Nat;

    uri : Text;
    etag : Text;
    lengthInBytes : Nat;
  };

  public type MediaID = Nat;

  // A full-fledged Media is created once the MediaData has been inserted into
  // the list of all Videate Media and is given an ID
  public type Media = MediaData and {
    // A serial, 0-based ID that also corresponds to the index into credits's
    // array of all Media on the platform.
    id : MediaID;
  };

  public type EpisodeData = {
    // The Feed in which this Episode is found. An Episode is only ever in one
    // Feed. To copy Episodes from other Feeds, or to re-release an episode in
    // the same Feed, a separate Episode is created.
    feedKey : FeedKey;

    title : Text;
    description : Text;
    mediaId : MediaID;
  };

  public type EpisodeID = Nat;

  // A full-fledged Episode is created once the EpisodeData has been inserted
  // into a Feed and is given an Id
  public type Episode = EpisodeData and {
    feedKey : FeedKey;

    // The serial 0-based id of the episode (i.e. the first Episode in a feed
    // is Episode 0, not Episode 1). This Episode exists at this index into
    // this Episode's Feed's array of EpisodeIDs. This does not necessarily
    // match the index into the textual list of Episodes returned when
    // requesting a Feed as rss, since some Episodes may be excluded from that
    // list after being removed from the Feed, though the rest of the Episodes
    // retain their EpisodeId.
    id : EpisodeID;

    // The token_id that was provided when an NFT for this Episode was minted.
    // This corresponds to an NFT stored in the "nft" module. "Null" implies
    // that no NFT for this Episode has yet been minted.
    nftTokenId : ?Nat64;
  };

  // Add putEpisode and putMediaAndEpisode in credits.mo to make use of this
  // type
  // public type PutEpisodeData = {
  //   #add : {
  //     episodeData : EpisodeData;
  //   };
  //   #update : {
  //     episode : Episode;
  //   };
  // };

  public type FeedKey = Text;

  public type Feed = {
    // A string that uniquely identifies this Feed among all Videate Feeds. As
    // this is part of the URL for the feed, creators get to choose their
    // FeedKey and it must be unique among all Feeds on Videate. FeedKeys must
    // only contain lower case letters, numbers and dashes.
    key : FeedKey;

    title : Text;
    subtitle : Text;
    description : Text;
    link : Text;
    author : Text;
    email : Text;
    imageUrl : Text;
    owner : Principal;

    // Usually this will look like [0, 1, 2, 3, ...] but if Episodes are
    // removed from the feed, numbers will be omitted from this array
    episodeIds : [EpisodeID];
  };

  public type CreditsError = {
    #Unauthorized;
    #FeedNotFound;
    #EpisodeNotFound;
    #KeyExists;
    #InvalidOwner;
    #Uninitialized : Text;
    #Other : Text;
  };

  public type SearchResult<T> = Result.Result<T, CreditsError>;

  public type EpisodeSearchResult = SearchResult<Episode>;

  public type PutSuccess = {
    #Added;
    #Updated;
  };

  public type PutResult = Result.Result<PutSuccess, CreditsError>;

  // Contributor: a causal factor in the existence or occurrence of something
  // All users (creators, consumers and supporters) are contributors
  // public type Contributor = {
  //     uploads: [Episode];
  // }
};
