# Bootstrap Kubernetes on Google Cloud (GKE) and other subsystems

```plain
git clone https://github.com/starkandwayne/bootstrap-gke.git
cd bootstrap-gke

direnv allow
# or
export PATH=$PWD/bin:$PATH
```

To deploy a GKE cluster:

```plain
bootstrap-gke up
```

But there are many subsystems that can be conveniently deployed after your cluster is setup:

```plain
$ bootstrap-gke
Bootstrap GKE and subsystems:
  up [--helm|--tiller] -- deploys secure Helm
     [--cf|--eirini]   -- deploys Cloud Foundry/Eirini
     [--kpack]         -- deploys kpack to build images with buildpacks
     [--tekton]        -- deploys Tekton CD
     [--knative]       -- deploys Knative Build/Serving/Istio
     [--knative-addr-name name] -- map GCP address to ingress gateway
     [--knative-build] -- deploys nightly Knative Build
     [--kubeapp]               -- deploys Kubeapps
     [--service-catalog|--sc]  -- deploys Helm/Service Catalog
     [--cf-broker]     -- deploys Helm/Service Catalog/Cloud Foundry Service Broker
  down                          -- destroys GKE cluster
```

### Configuration

There are several environment variables that can be set to override defaults:

```bash
export PROJECT_NAME=${PROJECT_NAME:-$(gcloud config get-value core/project)}
export CLUSTER_REGION=${CLUSTER_REGION:-$(gcloud config get-value compute/region)}
export CLUSTER_ZONE=${CLUSTER_ZONE:-$(gcloud config get-value compute/zone)}
export CLUSTER_NAME=${CLUSTER_NAME:-$(whoami)-dev}
export MACHINE_TYPE=${MACHINE_TYPE:-n1-standard-2}
```

## Shutdown

To destroy the GKE cluster:

```plain
bootstrap-gke down
```
