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

Run dfx and deploy the `serve` canister

```
cd videate/credits
dfx start --background
dfx deploy serve
```

Navigate to a feed!

Use an existing feed key and the correct canisterId for the `serve` canister)

http://127.0.0.1:8002/example_feed_key?canisterId=rrkah-fqaaa-aaaaa-aaaaq-cai

Use localhost.run to expose the feed to outside networks, e.g. for testing on a
phone

```
ssh -R 80:localhost:8002 localhost.run
```

Then subscribe in a podcatcher to the address printed out, e.g.:

https://0d16ad07d6e56a.localhost.run/example_feed_key?canisterId=rrkah-fqaaa-aaaaa-aaaaq-cai

Deploy to the Internet Computer:

dfx deploy --network ic

Navigate to a feed hosted on the Internet Computer. Note that ".raw.ic0.app"
must be used, not just ".ic0.app" since we're not hosting static files.

https://mvjun-2yaaa-aaaah-aac3q-cai.raw.ic0.app/example_feed_key

### Prerequisites

[Install the DFINITY Canister SDK](https://sdk.dfinity.org/docs/quickstart/quickstart.html#download-and-install)

## Authors

* **Mike Miller** - *Initial work* - [mymikemiller](https://github.com/mymikemiller)
