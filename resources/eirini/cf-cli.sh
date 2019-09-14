#!/bin/bash

set -eu

api_ip=$(kubectl get svc -n scf scf-router-0 -o json | jq -r .spec.clusterIP)
# darwin
admin_password=$(kubectl get secret -n scf scf.var-cf-admin-password -o json | jq -r .data.password | base64 -D)
# linux
# admin_password=$(kubectl get secret -n scf scf.var-cf-admin-password -o json | jq -r .data.password | base64 -d)

kubectl delete deployment -n scf cf-terminal || true

kubectl create -n scf -f - <<STDIN
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cf-terminal
  labels:
    app: cf-terminal
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cf-terminal
  template:
    metadata:
      labels:
        app: cf-terminal
    spec:
      hostAliases:
      - ip: "${api_ip}"
        hostnames:
        - "app1.scf.suse.dev"
        - "app2.scf.suse.dev"
        - "app3.scf.suse.dev"
        - "login.scf.suse.dev"
        - "api.scf.suse.dev"
        - "uaa.scf.suse.dev"
        - "doppler.scf.suse.dev"
        - "log-stream.scf.suse.dev"
      containers:
      - name: cf-terminal
        image: governmentpaas/cf-cli
        command: ["bash", "-c"]
        args:
        - cf api --skip-ssl-validation api.scf.suse.dev;
          cf login -u admin -p ${admin_password} ;
          cf create-org aiur;
          cf target -o aiur;
          cf create-space saalok;
          cf target -s saalok;
          git clone https://github.com/rohitsakala/cf-hello-worlds.git ;
          echo "Now ssh into this pod" ;
          echo "export podname=\\\$(kubectl get pods -l app=cf-terminal --template '{{(index .items 0).metadata.name}}' -n scf)" ;
          echo "kubectl -n scf exec -it \"\\\$podname\" -- /bin/bash" ;
          sleep 3600000;
STDIN

