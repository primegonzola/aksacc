#!/bin/bash

/AttestationClient -o token>> /attestation_output

JWT=$(cat /attestation_output)

echo -n $JWT | cut -d "." -f 1 | base64 -d 2>/dev/null | jq . > /logs/attestation_output_1.log
echo -n $JWT | cut -d "." -f 2 | base64 -d 2>/dev/null | jq . > /logs/attestation_output_2.log
