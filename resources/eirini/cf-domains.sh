#!/bin/bash

# Returns a JSON object of available domains in current CF
# Used for `kwt net start --dns-map-exec "cf-domains.sh"`
#
# Output example: {"scf.suse.dev":["35.184.47.142"]}
#
# See https://github.com/k14s/kwt/blob/master/docs/network.md#cheatsheet

: ${CF_SYSTEM_DOMAIN:=scf.suse.dev}
: ${CF_NAMESPACE:=scf}
: ${API_IP:=$(kubectl get svc -n ${CF_NAMESPACE} scf-router-0 --template '{{.spec.clusterIP}}')}

# If no connection to CF yet (kwt not running), then return static JSON
#       {"scf.suse.dev":["35.184.47.142"]}
# echo "{}" | jq -r --arg api_ip "$API_IP" --arg domain $CF_SYSTEM_DOMAIN '{($domain): [$api_ip]}'

cf curl /v3/domains | jq -r --arg api_ip "$API_IP" '.resources | map({(.name): [$api_ip]}) | add'
