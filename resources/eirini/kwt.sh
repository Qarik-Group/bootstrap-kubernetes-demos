#!/bin/bash

# https://github.com/k14s/kwt/blob/master/docs/network.md

set -eu

: ${CF_SYSTEM_DOMAIN:=scf.suse.dev}
: ${CF_NAMESPACE:=scf}
: ${API_IP:=$(kubectl get svc -n ${CF_NAMESPACE} scf-router-0 --template '{{.spec.clusterIP}}')}
export API_IP

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Mapping *.${CF_SYSTEM_DOMAIN} to internal IP ${API_IP}..."
echo
echo "Login with:"
echo "cf login -a https://api.${CF_SYSTEM_DOMAIN} --skip-ssl-validation -u admin \\"
echo '   -p "$(kubectl get secret -n scf scf.var-cf-admin-password -o json | jq -r .data.password | base64 --decode)"'
echo
# Need to run --dns-map first, so that admin can login first, to allow "cf curl" to work
sudo -E kwt net start --dns-map ${CF_SYSTEM_DOMAIN}=${API_IP} --namespace scf

# After "cf login", can run this line:
# sudo -E kwt net start --dns-map-exec "$DIR/cf-domains.sh" --namespace scf

# Maybe need a CFDomains Operator that looks into CF API, and create K8s records
# for each Domain; so that kwt can discover them without direct access to CF?
