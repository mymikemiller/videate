#!/bin/bash

# Load environment variables from the .env file
source .env

DEPLOY_ENV=${DEPLOY_ENV}
WALLET_ID=${WALLET_ID}

if [ "$DEPLOY_ENV" == "prod" ]; then
    echo "env: prod"

  DEPLOY_NETWORK="--network ic"
  DEPLOY_WALLET="" # was the following, but seems we don't need it: DEPLOY_WALLET="--wallet=${WALLET_ID}"
  DEPLOY_ARG="(true)"
else
    echo "env: dev"

  DEPLOY_NETWORK=""
  DEPLOY_WALLET=""
  DEPLOY_ARG="(false)"
fi


# Deploy
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} file_storage --argument="${DEPLOY_ARG}"
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} file_scaling_manager --argument="${DEPLOY_ARG}"
dfx deploy ${DEPLOY_NETWORK} ${DEPLOY_WALLET} frontend

# Check version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call file_storage version
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call file_scaling_manager version

# Init
dfx canister ${DEPLOY_NETWORK} ${DEPLOY_WALLET} call file_scaling_manager init
