#!/bin/bash

# https://github.com/k14s/kwt/blob/master/docs/network.md

set -eu

: ${CF_SYSTEM_DOMAIN:=scf.suse.dev}
: ${CF_NAMESPACE:=scf}

api_ip=$(kubectl get svc -n ${CF_NAMESPACE} scf-router-0 --template '{{.spec.clusterIP}}')
echo "Mapping *.${CF_SYSTEM_DOMAIN} to internal IP ${api_ip}..."
echo
echo "Login with:"
echo 'admin_password=$(kubectl get secret -n scf scf.var-cf-admin-password -o json | jq -r .data.password | base64 -D)'
echo 'cf login -a https://api.${CF_SYSTEM_DOMAIN} --skip-ssl-validation -u admin -p "${admin_password}"'
echo
sudo -E kwt net start --dns-map ${CF_SYSTEM_DOMAIN}=${api_ip} --namespace scf