#!/bin/bash

/AttestationClient -o token >>/attestation_output

JWT=$(cat /attestation_output)

echo -n $JWT | cut -d "." -f 1 | base64 -d 2>/dev/null | jq . >/logs/attestation_output_1.log
echo -n $JWT | cut -d "." -f 2 | base64 -d 2>/dev/null | jq . >/logs/attestation_output_2.log

# check some basic things for now
ATTESTATION_TYPE=$(cat /logs/attestation_output_2.log | jq -r '."x-ms-attestation-type"')
if [[ "${ATTESTATION_TYPE}" != "azurev" ]]; then
    # can't be
    echo "Failure: Attestation type is ${ATTESTATION_TYPE} and not azurevm"
    exit 1
fi
