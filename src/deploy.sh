#!/bin/bash
AKS_CLUSTER_NAME="${1}"
ASK_POOL_NAME="${2}"
AKS_NAMESPACE="${3}"
ACR_NAME="${4}"

APP_NAME="acc-sample-webapp"
APP_IMAGE_NAME="acc-sample-webapp"
APP_IMAGE_NAME_FQDN=${ACR_NAME}.azurecr.io/${APP_IMAGE_NAME}:latest
ATTESTATION_IMAGE_NAME="acc-attestation-reporter"
ATTESTATION_IMAGE_NAME_FQDN=${ACR_NAME}.azurecr.io/${ATTESTATION_IMAGE_NAME}:latest

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
    cp ../src/get-attestation-report.sh . &&
    docker build -f ./aks-linux-sample/cvm-attestation.Dockerfile -t $ACR_NAME.azurecr.io/${ATTESTATION_IMAGE_NAME}:latest . &&
    az acr login --name $ACR_NAME &&
    docker push $ACR_NAME.azurecr.io/${ATTESTATION_IMAGE_NAME}:latest &&
    popd

# lets prepare web app image
docker build -f webapp.Dockerfile -t $ACR_NAME.azurecr.io/acc-sample-webapp:latest . &&
    az acr login --name $ACR_NAME &&
    docker push $ACR_NAME.azurecr.io/acc-sample-webapp:latest

# delete the existing namespace
kubectl delete namespace ${AKS_NAMESPACE}

# create the namespace
kubectl create namespace ${AKS_NAMESPACE}

# lets deploy the app with attestation as init container
cat ./init.yaml | sed \
    -e "s|<APP_NAME>|${APP_NAME}|" \
    -e "s|<APP_IMAGE_NAME>|${APP_IMAGE_NAME_FQDN}|" \
    -e "s|<ATTESTATION_IMAGE_NAME>|${ATTESTATION_IMAGE_NAME_FQDN}|" | kubectl apply -n ${AKS_NAMESPACE} -f -

# inspect locally if needed
echo "To debug locally execute following command:\n"
echo "kubectl exec --stdin --tty ${APP_NAME}  -n ${AKS_NAMESPACE} -- /bin/bash"

# check if service and pod are running
kubectl get service -n ${AKS_NAMESPACE}
kubectl get pods -n ${AKS_NAMESPACE} -w

