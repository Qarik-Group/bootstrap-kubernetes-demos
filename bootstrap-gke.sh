#!/bin/bash

set -eu

export CLUSTER_NAME=${CLUSTER_NAME:-knative}
export CLUSTER_REGION=${CLUSTER_REGION:-us-west1}
export CLUSTER_ZONE=${CLUSTER_ZONE:-us-west1-c}

usage() {
    echo "Bootstrap Kube/Helm/Knative on GKE"
    echo "  up [--helm|--tiller] [--knative] -- deploys GKE, optionally installs Helm, Knative"
    echo "  down                             -- destroys GKE cluster"
}

down() {
  gcloud container clusters delete $CLUSTER_NAME --region $CLUSTER_ZONE
}

up() {
  errors=
  [[ "$(which gcloud)X" == "X" ]] && { echo "ERROR: missing 'gcloud' CLI from \$PATH"; errors=1; }
  [[ "$(which helm-manager)X" == "X" ]] && { echo "ERROR: missing 'helm-manager' CLI from \$PATH"; errors=1; }
  [[ "$(which knctl)X" == "X" ]] && { echo "ERROR: missing 'knctl' CLI from \$PATH"; errors=1; }
  [[ "$errors" == "1" ]] && { exit 1; }

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

  [[ "${helm:-}" == "1" ]] && { helm-manager up; }

  [[ "${knative:-}" == "1" ]] && {
    knctl install --exclude-monitoring

    knctl domain create --default --domain knative.starkandwayne.com

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
}

case "${1:-usage}" in
  up)
    shift
    while [[ $# -gt 0 ]]; do
      case "${1:-}" in
        --knative)
          export knative=1
          ;;
        --helm|--tiller)
          export helm=1
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
