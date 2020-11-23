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

### Launch the Flutter frontend, hosted in the credits_assets canister

`http://127.0.0.1:8000/?canisterId=`

### Rebuild canisters

After making changes to canisters, perform the following. This will preserve the state of any variables marked `stable`.

```
dfx build
dfx canister install --all --mode=reinstall
```

### Rebuild frontend

Before rebuilding canisters as above, make sure all necessary assets are in place. For example, `videate/credits/src/credits_assets/public/manage` is a symlink into the `manage` flutter project's web build output, so you'll need to build the `manage` frontend for web first:

```
cd videate/manage
flutter web build
```

### Prerequisites

[nstall the DFINITY Canister SDK](https://sdk.dfinity.org/docs/quickstart/quickstart.html#download-and-install)

## Authors

* **Mike Miller** - *Initial work* - [mymikemiller](https://github.com/mymikemiller)
