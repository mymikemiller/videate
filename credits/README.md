# The Credits

A set of Internet Computer canisters (see https://dfinity.org/) that act as a
sort of database to handle and track user's media requests.

## Running Locally

```
cd credits
dfx start --background
dfx canister create --all
dfx build
dfx canister install --all
```

Note the canister IDs printed out for `credits` and `credits_assets`

### Launch the automatically-generated, interactive Candid frontend for the appropriate canister

`http://127.0.0.1:8000/candid?canisterId=`

### Launch the frontend, hosted in the credits_assets canister

`http://127.0.0.1:8000/?canisterId=`

### Rebuild canisters

After making changes to canisters, perform the following. This will preserve the state of any variables marked `stable`.

```
dfx build
dfx canister install --all --mode=reinstall
```

## Generating XML feeds from The Credits data

Run dfx and deploy the `credits` and `serve` canister

```
cd videate/credits
dfx start --background
dfx deploy credits
dfx deploy serve
```

The [ic-http-lambda](https://github.com/nomeata/ic-http-lambda/) server must be
running so http requests can be received, translated into canister requests,
performed and returned as xml. Start the server by launching nomeata's server
locally on the same machine running the dfx server, using the following args:
--force-canister-id {credits canister id} --replica-url {local dfx replica url}

Note that, to run non-locally, the ic-http-lambda server will need to be
deployed somewhere, as nomeata did at https://<canister_id>.ic.nomeata.de/

A command like the following might work. Make sure to build the ic-http-lambda
project, and use credits's canister id and the correct port for replica-url
(printed shortly after running `dfx start`)

```
~/OneDrive/Projects/Web/ic-http-lambda/target/debug/ic-http-lambda --force-canister-id ryjl3-tyaaa-aaaaa-aaaba-cai --replica-url http://localhost:56605/
```

When the ic-http-lambda server is running and the canisters are deployed,
navigate to a feed!

Hard-coded sample feed:
``` 
http://127.0.0.1:7878/
```

Use localhost.run to expose the feed to outside networks, e.g. for testing on a
phone

```
ssh -R 80:localhost:7878 localhost.run
```

Then subscribe in a podcatcher to the address printed out

### Prerequisites

[Install the DFINITY Canister SDK](https://sdk.dfinity.org/docs/quickstart/quickstart.html#download-and-install)

## Authors

* **Mike Miller** - *Initial work* - [mymikemiller](https://github.com/mymikemiller)
