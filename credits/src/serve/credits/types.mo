import Result "mo:base/Result";
import Buffer "mo:base/Buffer";

module {
  // Used to store the contents of the Credits canister in stable types
  // between upgrades
  public type StableCredits = {
    feedEntries : [(Text, Feed)];
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

  public type Media = {
    // The source of the media, which contains information about how to
    // access the media on the platform on which it was originally released
    source : Source;

    // Everyone who participated in the media's creation or consumption
    // contributors: [Contributor];

    // The duration of the media in microseconds
    durationInMicroseconds : Nat;

    uri : Text;
    etag : Text;
    lengthInBytes : Nat;

    // not using for now as it creates a circular dependency. See
    // https://forum.dfinity.org/t/circular-reference-support-in-motoko-an-object-containing-itself-downstream-while-remaining-shared-and-stable/16262
    // All Episodes this Media is used in. The first item in this list is the
    // Episode this Media was originally created for. This is mutable (var) so
    // we can create a new Episode and then add it to its Media's episodes
    // array by reassigning that array to a new one containing the new Episide.
    // episodes : [Episode];
  };

  public type EpisodeData = {
    title : Text;
    description : Text;
    media : Media;
  };

  // A full-fledged Episode is created once the EpisodeData has been inserted
  // into a Feed and is given a Number
  public type Episode = EpisodeData and {
    // The Feed in which this Episode is found. An Episode is only ever in one
    // Feed. To copy Episodes from other Feeds, or to re-release an episode in
    // the same Feed, a separate Episode is created. note: this creates a
    // circular reference, which means Episode and Feed cannot be shared (i.e.
    // represented in candid)
    // todo: switch to feedKey here
    feed : Feed;

    // The serial 1-based number of the episode. This Episode exists at index
    // {number-1} into this Episode's Feed's array of Episodes. This does not
    // necessarily match the index into the list of Episodes returned when
    // requesting a Feed as rss, since some Episodes may be excluded from that
    // list after being removed from the Feed, though the rest of the Episodes
    // retain their index.
    number : Nat;

    // The token_id that was provided when an NFT for this Episode was minted.
    // This corresponds to an NFT stored in the "nft" module. "Null" implies
    // that no NFT for this Episode has yet been minted.
    nftTokenId : ?Nat64;
  };

  public type FeedKey = Text;

  public type Feed = {
    // A string that uniquely identifies this Feed among all Videate Feeds
    key : Text;

    title : Text;
    subtitle : Text;
    description : Text;
    link : Text;
    author : Text;
    email : Text;
    imageUrl : Text;
    owner : Principal;
    episodes : [Episode];
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

  public type PutEpisodeSuccess = {
    #Added : { episode : Episode };
    #Updated;
  };

  public type PutEpisodeResult = Result.Result<PutEpisodeSuccess, CreditsError>;

  // Contributor: a causal factor in the existence or occurrence of something
  // All users (creators, consumers and supporters) are contributors
  // public type Contributor = {
  //     uploads: [Episode];
  // }
};
