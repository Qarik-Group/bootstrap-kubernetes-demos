#!/bin/bash

set -eu

export CLUSTER_NAME=${CLUSTER_NAME:-knative}
export CLUSTER_REGION=${CLUSTER_REGION:-us-west1}
export CLUSTER_ZONE=${CLUSTER_ZONE:-us-west1-c}

usage() {
    echo "Bootstrap Kube/Helm/Knative on GKE"
    echo "  up [--helm|--tiller]         -- deploys Helm"
    echo "     [--service-catalog|--sc]  -- deploys Helm/Service Catalog"
    echo "     [--cf-broker]     -- deploys Helm/Service Catalog/Cloud Foundry Service Broker"
    echo "     [--knative]       -- deploys Knative Build/Serving/Istio"
    echo "     [--knative-build] -- deploys nightly Knative Build"
    echo "  down                 -- destroys GKE cluster"
}

down() {
  gcloud container clusters delete $CLUSTER_NAME --region $CLUSTER_ZONE
}

up() {
  errors=
  [[ "$(which gcloud)X" == "X" ]] && { echo "ERROR: missing 'gcloud' CLI from \$PATH"; errors=1; }
  [[ "$(which kubectl)X" == "X" ]] && { echo "ERROR: missing 'kubectl' CLI from \$PATH"; errors=1; }
  [[ "${helm:-}" == "1" && "$(which helm-manager)X" == "X" ]] && { echo "ERROR: missing 'helm-manager' CLI from \$PATH"; errors=1; }
  [[ "${cf_broker:-}" == "1" ]] && {
    : ${CF_API:?required for --cf-broker}
    : ${CF_USERNAME:?required for --cf-broker}
    : ${CF_PASSWORD:?required for --cf-broker}
    : ${CF_ORGANIZATION:?required for --cf-broker}
    : ${CF_SPACE:?required for --cf-broker}
    : ${CF_MARKETPLACE_BROKER_PATH:?need /path/to/cf-marketplace-servicebroker}
  }
  [[ "${knative:-}" == "1" && "$(which knctl)X" == "X" ]] && { echo "ERROR: missing 'knctl' CLI from \$PATH"; errors=1; }
  [[ "$errors" == "1" ]] && { exit 1; }

  [[ "${cf_broker:-}" == "1" ]] && {
    echo "Testing login to Cloud Foundry ${CF_API}..."
    cf api ${CF_API}
    cf auth ${CF_USERNAME} ${CF_PASSWORD}
    cf target -o ${CF_ORGANIZATION} -s ${CF_SPACE}
  }

  gcloud container clusters describe $CLUSTER_NAME --region $CLUSTER_ZONE 2>&1 > /dev/null || {
    gcloud container clusters create $CLUSTER_NAME \
      --region=$CLUSTER_ZONE \
      --cluster-version=latest \
      --machine-type=n1-standard-2 \
      --enable-autoscaling --min-nodes=1 --max-nodes=5 \
      --enable-autorepair \
      --scopes=service-control,service-management,compute-rw,storage-ro,cloud-platform,logging-write,monitoring-write,pubsub,datastore \
      --num-nodes=3

    kubectl create clusterrolebinding cluster-admin-binding \
      --clusterrole=cluster-admin \
      --user=$(gcloud config get-value core/account)
  }

  [[ "${helm:-}" == "1" ]] && {
    echo "Install/upgrade Tiller Server for Helm"
    helm-manager up
    helm repo update
  }
  [[ "${servicecatalog:-}" == "1" ]] && {
    echo "Install/upgrade Service Catalog via Helm"
    helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
    helm upgrade --install catalog svc-cat/catalog --namespace catalog --wait
  }
  [[ "${cf_broker:-}" == "1" ]] && {
    echo "Install/upgrade CF Marketplace Service Broker via Helm"
    helm upgrade --install --namespace catalog pws-broker $CF_MARKETPLACE_BROKER_PATH/helm --wait \
    --set "cf.api=$CF_API" \
    --set "cf.username=${CF_USERNAME:?required},cf.password=${CF_PASSWORD:?required}" \
    --set "cf.organizationGUID=$(jq -r .OrganizationFields.GUID ~/.cf/config.json)" \
    --set "cf.spaceGUID=$(jq -r .SpaceFields.GUID ~/.cf/config.json)"

    # TODO: move into a kubectl apply -f manifest.yml
    kubectl create secret generic pws-broker-cf-marketplace-servicebroker-basic-auth \
      --from-literal username=broker \
      --from-literal password=broker

    sleep 2
    svcat register pws-broker-cf-marketplace-servicebroker \
      --url http://pws-broker-cf-marketplace-servicebroker.catalog.svc.cluster.local:8080 \
      --scope cluster \
      --basic-secret pws-broker-cf-marketplace-servicebroker-basic-auth
  }

  [[ "${knative:-}" == "1" ]] && {
    echo "Install/upgrade Knative without monitoring"
    knctl install --exclude-monitoring

    knctl domain create --default --domain knative.starkandwayne.com

    echo "Deploy sanity test app to Knative"
    kubectl create ns bootstrap-test
    knctl deploy \
      --namespace bootstrap-test \
      --service hello \
      --image gcr.io/knative-samples/helloworld-go \
      --env TARGET=Bootstrap

    podStatus=Init
    while [[ "${podStatus}" != "Running" ]]; do
      sleep 2
      podStatus=$(kubectl get pods -n bootstrap-test -l serving.knative.dev/configuration=hello -o jsonpath="{.items[0].status.phase}")
      echo "  ${podStatus}"
    done
    knctl curl -n bootstrap-test -s hello
  }

  [[ "${knative_build:-}" == "1" ]] && {
    echo "Install/upgrade Knative Build"
    # kubectl apply -f https://storage.googleapis.com/knative-releases/build/latest/release.yaml --wait
    kubectl apply -f https://github.com/knative/build/releases/download/v0.1.0/release.yaml --wait
  }
}

case "${1:-usage}" in
  up)
    shift
    while [[ $# -gt 0 ]]; do
      case "${1:-}" in
        --knative)
          export knative=1
          ;;
        --knative-build)
          export knative_build=1
          ;;
        --helm|--tiller)
          export helm=1
          ;;
        --service-catalog|--sc)
          export helm=1
          export servicecatalog=1
          ;;
        --cf-broker)
          export helm=1
          export servicecatalog=1
          export cf_broker=1
          ;;
      esac
      shift
    done

    up
    ;;

  down)
      shift
      down
      ;;

  *)
      usage
      exit 1
      ;;
esac
