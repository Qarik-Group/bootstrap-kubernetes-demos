# Bootstrap Kubernetes and demonstrations

It is great to have a single tool to bring up a Kubernetes cluster, and install one or more demonstration/development/experimentation systems.

## Basic Usage

```plain
bootstrap-kubernetes-demos up --google --kpack --knative
bootstrap-kubernetes-demos up --google --scf
```

Later, to discard the cluster (if it was bootstrap by this tool):

```plain
bootstrap-kubernetes-demos down
```

The initial flags are remembered, so you can subsequently `up` again and the same system will be rebuilt or upgraded:

```plain
bootstrap-kubernetes-demos up
```

## Installation

```plain
git clone --recurse-submodules https://github.com/starkandwayne/bootstrap-kubernetes-demos.git
cd bootstrap-kubernetes-demos

direnv allow
# or
export PATH=$PWD/bin:$PWD/vendor/helm-tiller-manager/bin:$PATH
```

## Google Cloud

Login to Google Cloud:

```plain
gcloud auth login
```

Target a Google Cloud region/zone:

```plain
gcloud config set compute/region australia-southeast1
gcloud config set compute/zone   australia-southeast1-a
```

To deploy a GKE cluster:

```plain
bootstrap-kubernetes-demos up --google
```

### Google Cloud Configuration

There are several environment variables that can be set to override defaults:

```bash
: ${PROJECT_NAME:=$(gcloud config get-value core/project)}
: ${CLUSTER_REGION:=$(gcloud config get-value compute/region)}
: ${CLUSTER_ZONE:=$(gcloud config get-value compute/zone)}
: ${CLUSTER_NAME:="$(whoami)-dev"}
: ${CLUSTER_VERSION:=latest}
: ${MACHINE_TYPE:=n1-standard-2}
```

## Subsystems

But there are many subsystems that can be conveniently deployed after your cluster is setup:

```plain
$ bootstrap-kubernetes-demos
Bootstrap Kubernetes and/or subsystems for demonstrations:
  up
     [--gke|--google]       -- bootstrap new GKE cluster
     [--credhub-store path] -- store GKE cluster into Credhub path/to/secrets

     [--helm|--tiller]      -- deploys secure Helm
     [--cf|--scf|--eirini]  -- deploys Cloud Foundry/Eirini
     [--cf-operator]        -- deploys only CF Operator
     [--kpack]              -- deploys kpack to build images with buildpacks
     [--tekton]             -- deploys Tekton CD
     [--knative]            -- deploys Knative Serving/Eventing/Istio
     [--knative-addr-name name] -- map GCP address to ingress gateway
     [--kubeapp]                -- deploys Kubeapps
     [--service-catalog|--sc]   -- deploys Helm/Service Catalog
     [--cf-broker]              -- deploys Helm/Service Catalog/Cloud Foundry Service Broker

  down                        -- destroys cluster, if originally bootstrapped
  kwt                         -- runs kwt cli to map HTTP/TCP into cluster
  clean                       -- cleans up cached state files
```

### Helm / Tiller

Helm v2 requires a Kubernetes-running component Tiller. The `bootstrap-kubernetes-demos up --helm` command (and others that depend on Helm for installation) will create Tiller for you.

It will also secure it with generated TLS certificates (stored in `state/` folder, and copied into `~/.helm`).

To use `helm` commands yourself, please set the following env var to tell `helm` to use TLS:

```shell
export HELM_TLS_VERIFY=true
```

Put that in your `.profile` for all terminal sessions.

### Cloud Foundry / Eirini / Quarks

To bootstrap GKE, and then install Cloud Foundry (with Eirini/Quarks) use the `--cf` flag (or `--scf`, or `--eirini` flags):

```plain
bootstrap-kubernetes-demos up --cf
```

You can override some defaults by setting the following environment variables before running the command above:

```bash
: ${CF_SYSTEM_DOMAIN:=scf.suse.dev}
: ${CF_NAMESPACE:=scf}
```

Currently this CF deployment does not setup a public ingress into the Cloud Foundry router. But fear not. You can run `kwt net start` to proxy any requests to CF or to applications running on CF from your local machine.

The [`kwt`](https://github.com/k14s/kwt) CLI can be installed to MacOS with Homebrew:

```plain
brew install k14s/tap/kwt
```

Run the helper script to configure and run `kwt net start` proxy services:

```plain
bootstrap-kubernetes-demos kwt
```

Provide your sudo root password at the prompt.

The `kwt net start` command launches a new pod `kwt-net` in the `scf` namespace, which is used to proxy your traffic into the cluster.

The `kwt` proxy is ready when the output looks similar to:

```plain
...
07:17:27AM: info: KubeEntryPoint: Waiting for networking pod 'kwt-net' in namespace 'scf' to start...
...
07:17:47AM: info: ForwardingProxy: Ready!
```

In another terminal you can now `cf login` and `cf push` apps:

```plain
cf login -a https://api.scf.suse.dev --skip-ssl-validation -u admin \
   -p "$(kubectl get secret -n scf scf.var-cf-admin-password -o json | jq -r .data.password | base64 -D)"
```

You can now create organizations, spaces, and deploy applications:

```plain
cf create-space dev
cf target -s dev
```

Next, upgrade all the installed buildpacks:

```plain
curl https://raw.githubusercontent.com/starkandwayne/update-all-cf-buildpacks/master/update-only.sh | bash
```

Find sample applications at https://github.com/cloudfoundry-samples.

```plain
git clone https://github.com/cloudfoundry-samples/cf-sample-app-nodejs
cd cf-sample-app-nodejs
cf push
```

Load the application URL into your browser, accept the risks of "insecure" self-signed certificates, and your application will look like:

![app](https://cl.ly/9ebcd7a4e4b9/cf-nodejs-app.png)
