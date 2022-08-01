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
}
