module {
    /* Serve */
    public type HeaderField = (Text, Text);
    
    public type Token = {};

    public type StreamingCallbackHttpResponse = {
        body : Blob;
        token : Token;
    };

    public type StreamingStrategy = {
        #Callback : {
            callback : shared Token -> async StreamingCallbackHttpResponse;
            token : Token;
        };
    };

    public type HttpRequest = {
        method: Text;
        headers: [HeaderField];
        url: Text;
        body: Blob;
    };

    public type HttpResponse = {
        status_code: Nat16;
        headers: [HeaderField];
        body: Blob;
        streaming_strategy : ?StreamingStrategy;
    };

    public type UriTransformer = Text -> Text;

    /* Credits */

    // Used to store the contents of the Credits canister in stable types
    // between upgrades
    public type StableCredits = {
        feedEntries: [(Text, Feed)];
    };

    // Represents the platform where the media was originally released, e.g. youtube
    public type Platform = {
        // The Uri to the platform's main page, e.g. 'http://www.youtube.com'
        uri: Text;

        // An id unique among all platforms, e.g. 'youtube'
        id: Text;
    };

    // Represents the original source of media, e.g. a video's page on YouTube
    public type Source = {
        // The source platform, e.g. youtube
        platform: Platform;

        // The Uri where the media can be accessed on the source platform
        uri: Text;

        // An id unique among all media on the source platform, likely part of
        // the uri
        id: Text;

        // The date the media was released on the source platform. Example:
        // 1970-01-01T00:00:00.000Z
        releaseDate: Text;
    };

    public type Media = {
        title: Text;
        description: Text;

        // The source of the media, which contains information about how to access
        // the media on the platform on which it was originally released
        source: Source;

        // Everyone who participated in the media's creation or consumption
        // contributors: [Contributor];

        // The duration of the media in microseconds
        durationInMicroseconds: Nat;

        // From ServedMedia when cloning, but all media on the InternetComputer
        // is served, so these values are just stored on Media directly
        uri: Text;
        etag: Text;
        lengthInBytes: Nat;
    };

    public type Feed = {
        title: Text;
        subtitle: Text;
        description: Text;
        link: Text;
        author: Text;
        email: Text;
        imageUrl: Text;
        mediaList: [Media];
    };
    
    // Contributor: a causal factor in the existence or occurrence of something
    // All users (creators, consumers and supporters) are contributors
    // public type Contributor = {
    //     uploads: [Media];
    // }
}
