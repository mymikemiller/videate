module {
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

        // The date the media was released on the source platform
        // releaseDate: DateTime;
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
    
    public type Media = {
        title: Text;
        description: Text;

        // The source of the media, which contains information about how to access
        // the media on the platform on which it was originally released
        source: Source;

        // Everyone who participated in the media's creation or consumption
        // contributors: [Contributor];

        // The length of the media in nanoseconds
        //duration: Nat;

        // From ServedMedia
        uri: Text;
        // etag: Text;
        // lengthInBytes: Nat;
    };

    // Contributor: a causal factor in the existence or occurrence of something
    // All users (creators, consumers and supporters) are contributors
    // public type Contributor = {
    //     uploads: [Media];
    // }
};
