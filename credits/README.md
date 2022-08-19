# The Credits

A set of Internet Computer canisters (see https://dfinity.org/) that act as a
sort of database to handle and track users` media requests.

# Running Locally

```
cd credits
```
In one terminal:
```
dfx start
```
In another, do one of the following:

1. Create, build and install all canisters
```
dfx canister create --all
dfx build
dfx canister install --all
```
2. Or do the above in a single call
```
dfx deploy
```
3. If this is the first deploy to a replica (e.g. after using `dfx start --clean`), also initialize the NFT module:
```
dfx canister call serve initializeNft
```
4. Run the frontend on port 3000 with hot reload capability in Chromium browsers
```
npm start
```

Remember to use port 3000 when loading the site you're testing.

Note the canister IDs printed out for `serve` and `frontend`, or located in .dfx/local/canister_ids.

## Running Internet Identity Locally

To use a locally running copy of Internet Identity when logging in to the web
interface for NODE_ENV=development builds (production builds default to using
the actual Internet Identity service), you need to build and start the
[Internet Identity canister](https://github.com/dfinity/internet-identity).
Clone that repository and build and start according to the instructions. The
startup command is duplicated here for convenience but the Internet Identity
readme's command should be used (and this README should be updated) if they differ.
dd
Run this, updating the path to point to your local copy of internet-identity:

```bash
cd ~/Library/CloudStorage/OneDrive-Personal/Projects/Web/internet-identity/; rm -rf .dfx; II_FETCH_ROOT_KEY=1 dfx deploy --no-wallet --argument '(null)'
```

Ensure that the value printed out for "Installing code for canister
internet_identity" (also found in
internet-identity/.dfx/local/canister_ids.json under "internet_identity") is
written in webpack.config.js for the development II_URL.

Once that is running locally (and so are this package's canisters), navigating
to http://localhost:8000?canisterId=[local frontend cid] will load
the login UI and authenticating with Internet Identity will redirect to
http://localhost:8000/authorize?canisterId=[cid found above]

### Launch the automatically-generated, interactive Candid frontend for the appropriate canister

`localhost:8000/canisterId={__CANDID_UI cid from .dfx/local/canisters}`

### Launch the frontend, hosted in the frontend canister

#### Locally:

`localhost:8000/?canisterId={frontend cid from .dfx/local/canisters}`

If you get a "Register Device. This user does not have access to this wallet."
page when clicking the login link (likely after a `dfx start --clean`),
re-deploy the Internet Identity canister by following the instructions above.

If you get a page asking you to enter in a canisterID, try changing "localhost"
to "127.0.0.1" or "0.0.0.0" (though when using 0.0.0.0, navigator.clipboard is
unavailable so the copy url function won't work)

#### Hosted on the Internet Computer:

https://44ejt-7yaaa-aaaao-aabqa-cai.raw.ic0.app/?feedKey=tdts

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

After the initial deploy, initialize the serve canister to give us (the dfx
user) authorization to manage the NFTs as a custodian:

```
dfx canister call serve initialize
```

Navigate to a feed!

Use an existing feed key and the correct local canisterIds for the `serve` and
`frontend` canister)

localhost:8000/nsp?canisterId=rrkah-fqaaa-aaaaa-aaaaq-cai&frontendCid=r7inp-6aaaa-aaaaa-aaabq-cai&principal=s7v5n-xcubz-fcpgx-bmtwn-a7gvr-eigeg-idpzg-bsiuv-3th53-uee3c-2qe

To test locally hosted feeds on a phone, use localhost.run to expose the feed
to outside networks:

```
ssh -R 80:localhost:8000 localhost.run
```

Then subscribe in a podcatcher to the address printed out after "tunneled with
tls termination", e.g.:

https://8d0116fb626db2.lhrtunnel.link/example_feed_key?canisterId=r7inp-6aaaa-aaaaa-aaabq-cai&frontendCid=ryjl3-tyaaa-aaaaa-aaaba-cai&principal=TEST_PRINCIPAL

Make sure to specify the current cid for frontend from
.dfx/local/canister_ids.json so the generated videate settings links will work
properly, e.g.:

# Deploy to the Internet Computer:
```
dfx deploy --network ic --no-wallet
```
## Navigate to a feed hosted on the Internet Computer. 
### Note that ".raw.ic0.app" must be used, not just ".ic0.app" since we're not hosting static files.

https://mvjun-2yaaa-aaaah-aac3q-cai.raw.ic0.app/example_feed_key?principal=TEST_PRINCIPAL

### Prerequisites

[Install the DFINITY Canister SDK](https://sdk.dfinity.org/docs/quickstart/quickstart.html#download-and-install)

## Authors

* **Mike Miller** - *Initial work* - [mymikemiller](https://github.com/mymikemiller)
