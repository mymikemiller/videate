# The Credits

A set of Internet Computer canisters (see https://dfinity.org/) that act as a
sort of database to handle and track users` media requests.

## Running Locally

```
cd credits
dfx start --background
dfx canister create --all
dfx build
dfx canister install --all
```

Note the canister IDs printed out for `credits` and `credits_assets`

## Running Internet Identity Locally

To use a locally running copy of Internet Identity when logging in to the web
interface for NODE_ENV=development builds (production builds default to using
the actual Internet Identity service), you need to build and start the
[Internet Identity canister](https://github.com/dfinity/internet-identity).
Clone that repository and build and start according to the instructions. The
startup command is duplicated here for convenience but the Internet Identity
readme's command should be used (and this should be updated) if they differ.

Run this from the internet-identity folder:

```bash
II_FETCH_ROOT_KEY=1 dfx deploy --no-wallet --argument '(null)'
```

Ensure that the value printed out for "Installing code for canister
internet_identity" (also found in
internet-identity/.dfx/local/canister_ids.json under "internet_identity") is
written in webpack.config.js for the development II_URL.

Once that is running locally (and so are this package's canisters), navigating
to http://localhost:8000?canisterId=[local contributor_assets cid] will load
the login UI and authenticating with Internet Identity will redirect to
http://localhost:8000/authorize?canisterId=[cid found above]

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
