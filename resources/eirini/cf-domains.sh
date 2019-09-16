#!/bin/bash

# Returns a JSON object of available domains in current CF
# Used for `kwt net start --dns-map-exec "cf-domains.sh"`
#
# Output example: {"scf.suse.dev":["35.184.47.142"]}
#
# See https://github.com/k14s/kwt/blob/master/docs/network.md#cheatsheet

: ${CF_NAMESPACE:=scf}
: ${API_IP:=$(kubectl get svc -n ${CF_NAMESPACE} scf-router-0 --template '{{.spec.clusterIP}}')}

cf curl /v3/domains | jq -r --arg api_ip "$API_IP" '.resources | map({(.name): [$api_ip]}) | add'
