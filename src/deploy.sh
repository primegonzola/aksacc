#!/bin/bash
AKS_CLUSTER_NAME="${1}"
ASK_POOL_NAME="${2}"
ACR_NAME="${3}"

APP_IMAGE_NAME="acc-sample-webapp"
ATTESTATION_IMAGE_NAME="acc-attestation-reporter"

# clean up
rm -rf ../cccvma

# clone the attestation repo
pushd .. &&
    git clone https://github.com/Azure/confidential-computing-cvm-guest-attestation.git &&
    mv confidential-computing-cvm-guest-attestation cccvma &&
    cd cccvma &&
    rm -rf .git &&
    popd

# lets prepare cvm attestation image
pushd ../cccvma &&
    cp ../src/cvm-attestation.Dockerfile ./aks-linux-sample &&
    docker build -f ./aks-linux-sample/cvm-attestation.Dockerfile -t $ACR_NAME.azurecr.io/${ATTESTATION_IMAGE_NAME}:latest . &&
    az acr login --name $ACR_NAME &&
    docker push $ACR_NAME.azurecr.io/${ATTESTATION_IMAGE_NAME}:latest &&
    popd

# lets prepare web app image
docker build -f webapp.Dockerfile -t $ACR_NAME.azurecr.io/acc-sample-webapp:latest . &&
    az acr login --name $ACR_NAME &&
    docker push $ACR_NAME.azurecr.io/acc-sample-webapp:latest

# lets deploy the app with attestation as init container
cat ./init.yaml | sed \
    -e "s|<ATTESTATION_IMAGE_NAME>|${ATTESTATION_IMAGE_NAME}|" \
    -e "s|<APP_IMAGE_NAME>|${APP_IMAGE_NAME}|" | kubectl apply -f -

# check if running