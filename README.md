# Bootstrap Kubernetes and demonstrations

It is great to have a single tool to bring up a Kubernetes cluster, and install one or more demonstration/development/experimentation systems.

New Kubernetes clusters can be provisioned on:

* Google Kubernetes Engine (GKE)
* Azure Container Service (AKS)
* DigitalOcean Kubernetes
* Minikube

## Basic Usage

```plain
bootstrap-kubernetes-demos up --google --kubecf
bootstrap-kubernetes-demos up --azure --knative --kpack
bootstrap-kubernetes-demos up --digitalocean --rancher
bootstrap-kubernetes-demos up --minikube --cert-manager
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
export PATH=$PWD/bin:$PATH
```

## Minikube

First, install [Minikube](https://kubernetes.io/docs/setup/learning-environment/minikube/).

To start Minikube, plus additional subsystems:

```plain
bootstrap-kubernetes-demos up --minikube
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

## Azure

Also supported. Just doesn't have a documentation paragraph.

```plain
bootstrap-kubernetes-demos up --azure
```

## Digital Ocean

```plain
bootstrap-kubernetes-demos up --digitalocean
```

The Digital Ocean cluster will install 3 x 2 CPU/2Gb nodes, and will install the nginx-ingress controller.

## Subsystems

But there are many subsystems that can be conveniently deployed after your cluster is setup:

```plain
$ bootstrap-kubernetes-demos
Bootstrap Kubernetes and/or subsystems for demonstrations:
  up
     [--minikube|--local]   -- bootstrap Minikube
     [--gke|--google]       -- bootstrap new Google GKE cluster
     [--az|--azure]         -- bootstrap new Azure AKE cluster
     [--do|--digitalocean]  -- bootstrap new Digital Ocean cluster

     [--ingress|--nginx-ingress] -- deploys Nginx Ingress
     [--cert-manager]       -- deploys cert-manager
     [--k-rail|--krail]     -- deploys k-rail to enforce policies for end users
     [--helm|--tiller]      -- deploys secure Helm Tiller (deprecated)

     [--cf|--kubecf|--eirini] -- deploys Cloud Foundry/Eirini
     [--cf-operator]        -- deploys only CF Operator
     [--kpack]              -- deploys kpack to build images with buildpacks
     [--tekton]             -- deploys Tekton CD
     [--knative]            -- deploys Knative Serving/Eventing/Istio
     [--rancher]            -- deploys Rancher
     [--rio]                -- deploys Rancher Rio
     [--kubeapp]                -- deploys Kubeapps
     [--service-catalog|--sc]   -- deploys Helm/Service Catalog
     [--cf-broker]              -- deploys Helm/Service Catalog/Cloud Foundry Service Broker

  down                        -- destroys cluster, if originally bootstrapped
  clean                       -- cleans up cached state files
```

## Rancher

You can install the Rancher management tool into your cluster. It will also install cert-manager, which it uses.

```plain
bootstrap-kubernetes-demos up --digitalocean --rancher
```

Once the Rancher chart is installed, it will print out the URL for Rancher.

```plain
...
Browse to https://rancher.35.230.87.102.xip.io

Happy Containering!
Waiting for deployment "rancher" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "rancher" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "rancher" rollout to finish: 2 of 3 updated replicas are available...
deployment "rancher" successfully rolled out
```

NOTE: [rancher/rancher#16213](https://github.com/rancher/rancher/issues/16213)

Once you've logged into Rancher, the `local` cluster will not "provision". You need to edit and save it, and then the `local` cluster will be available.

## k-rail to enforce policies

> [k-rail](https://github.com/cruise-automation/k-rail) is a workload policy enforcement tool for Kubernetes. It can help you secure a multi tenant cluster with minimal disruption and maximum velocity.

```plain
bootstrap-kubernetes-demos up --k-rail
```

To demonstrate the various policies being enforced there is an example bad deployment that will fail to install:

```plain
bootstrap-system-k-rail example
```

## Helm / Tiller

**Deprecated** - Helm v3 no longer includes Tiller. There is a `helm3` branch of this repo which will stop installing Tiller. It is blocked on some of the other subsystem's still requiring tiller's install hooks.

Helm v2 requires a Kubernetes-running component Tiller. The `bootstrap-kubernetes-demos up --helm` command (and others that depend on Helm for installation) will create Tiller for you.

It will also secure it with generated TLS certificates (stored in `state/` folder, and copied into `~/.helm`).

To use `helm` commands yourself, please set the following env var to tell `helm` to use TLS:

```shell
export HELM_TLS_VERIFY=true
```

Put that in your `.profile` for all terminal sessions.

## Cloud Foundry / Eirini / Quarks

To bootstrap GKE, and then install Cloud Foundry (with Eirini/Quarks) use the `--cf` flag (or `--kubecf`, or `--eirini` flags). The explicit `--ingress` flag will automatically setup a default `.xip.io` system domain.

```plain
bootstrap-kubernetes-demos up --cf
bootstrap-kubernetes-demos up --google --cf
bootstrap-kubernetes-demos up --azure --cf
bootstrap-kubernetes-demos up --digitalocean --cf
```

Your Cloud Foundry Buildpacks will be automatically updated to the latest from GitHub, and each day a cronjob will run to update them again.

To target and login:

```plain
SYSTEM_DOMAIN=$(kubectl get secret kubecf.var-system-domain -ojsonpath='{.data.value}' | base64 --decode)
ADMIN_PASSWORD=$(kubectl get secret kubecf.var-cf-admin-password -ojsonpath='{.data.password}' | base64 --decode)

cf login -a https://api.$SYSTEM_DOMAIN --skip-ssl-validation -u admin -p $ADMIN_PASSWORD
```

This is also available via:

```plain
bootstrap-system-kubecf login
```

### Access to KubeCF

Currently this CF deployment does not setup a public ingress into the Cloud Foundry router. Nor will it ever set up your public DNS to map to your Cloud Foundry ingress/router.

But fear not. You can run `kwt net start` to proxy any requests to CF or to applications running on CF from your local machine.

The [`kwt`](https://github.com/k14s/kwt) CLI can be installed to MacOS with Homebrew:

```plain
brew install k14s/tap/kwt
```
Install KWT on linux:

```plain
wget https://github.com/k14s/kwt/releases/download/v0.0.5/kwt-linux-amd64 
chmod +x kwt-linux-amd64 && sudo mv kwt-linux-amd64 /usr/local/bin/kwt
```


Run the helper script to configure and run `kwt net start` proxy services:

```plain
bootstrap-system-kubecf kwt
```

Provide your sudo root password at the prompt.

The `kwt net start` command launches a new pod `kwt-net` in the `kubecf` namespace, which is used to proxy your traffic into the cluster.

The `kwt` proxy is ready when the output looks similar to:

```plain
...
07:17:27AM: info: KubeEntryPoint: Waiting for networking pod 'kwt-net' in namespace 'kubecf' to start...
...
07:17:47AM: info: ForwardingProxy: Ready!
```

### Deploy first app

In another terminal you can now `cf login` and `cf push` apps:

```plain
cf login -a https://api.kubecf.suse.dev --skip-ssl-validation -u admin \
   -p "$(kubectl get secret -n kubecf kubecf.var-cf-admin-password -o json | jq -r .data.password | base64 --decode)"
```

You can now create organizations, spaces, and deploy applications:

```plain
cf create-space dev
cf target -s dev
```

Find sample applications at [github.com/cloudfoundry-samples](https://github.com/cloudfoundry-samples).

```plain
git clone https://github.com/cloudfoundry-samples/cf-sample-app-nodejs
cd cf-sample-app-nodejs
cf push
```

Load the application URL into your browser, accept the risks of "insecure" self-signed certificates, and your application will look like:

![app](https://cl.ly/9ebcd7a4e4b9/cf-nodejs-app.png)

### Install a Service Broker

Let's install the [World's Simplest Service Broker](https://github.com/cloudfoundry-community/worlds-simplest-service-broker) via Helm, and register it as a service broker in our new Cloud Foundry.

```plain
helm repo add starkandwayne https://helm.starkandwayne.com
helm repo update

helm upgrade --install email starkandwayne/worlds-simplest-service-broker \
    --namespace brokers \
    --wait \
    --set "serviceBroker.class=smtp" \
    --set "serviceBroker.plan=shared" \
    --set "serviceBroker.tags=shared\,email\,smtp" \
    --set "serviceBroker.baseGUID=some-guid" \
    --set "serviceBroker.credentials=\{\"host\":\"mail.authsmtp.com\"\,\"port\":2525\,\"username\":\"ac123456\"\,\"password\":\"special-secret\"\}"
```

When this finishes you can now register it with your Cloud Foundry:

```plain
cf create-service-broker email \
    broker broker \
    http://email-worlds-simplest-service-broker.brokers.svc.cluster.local:3000

cf enable-service-access smtp
```

Note: this URL assumes you installed your broker in to the `--namespace brokers` namespace above.

The `smtp` service is now available to all users:

```plain
$ cf marketplace
Getting services from marketplace in org system / space dev as admin...
OK

service   plans    description               broker
smtp      shared   Shared service for smtp   email

$ cf create-service smtp shared email
$ cf delete-service smtp shared email
```

### Restart cf-operator

The `cf-operator` (from the Quarks project) is like a BOSH director for Kubernetes.

If you need/want to update it then you need to both delete some system webhooks and delete the pod (see discussion in [issue #436](https://github.com/cloudfoundry-incubator/cf-operator/issues/436)).

There is a `restart` helper you can run to do this:

```plain
bootstrap-system-cf-operator restart
```

## Knative

```plain
bootstrap-kubernetes-demos up --knative
```

This will install a small Istio (no mTLS between containers), Knative Serving, and Knative Eventing. Knative Build has been deprecated and is no longer considered to be part of Knative.

### Deploy First App

You can create Knative Services (Applications) using:

* core team CLI [`kn`](https://github.com/knative/client/)
* community CLI [`knctl`](https://github.com/cppforlife/knctl)
* Create resources of `services.serving.knative.dev` CRD (`ksvc` alias)

The latest `kn` CLI will be automatically downloaded for you and is used in the examples below.

```plain
kubectl create ns test-app
kn service create \
    sample-app-nodejs \
    --image starkandwayne/sample-app-nodejs:latest \
    --namespace test-app
```

This creates a `ksvc`:

```plain
kubectl get ksvc -n test-app
NAME                URL                                             LATESTCREATED               LATESTREADY                 READY   REASON
sample-app-nodejs   http://sample-app-nodejs.test-app.example.com   sample-app-nodejs-jrskg-1   sample-app-nodejs-jrskg-1   True
```

To see all the resources created, run:

```plain
kubectl get ksvc,rev,rt,cfg -n test-app
```

But how do we access the URL above?

### Access / Ingress with kwt

This Knative deployment does setup a public ingress via Istio, but it does not setup public DNS to map to your ingress IP. Additionally, the URL `http://sample-app-nodejs.test-app.example.com` is not a publicly valid DNS entry (`example.com`).

But fear not. You can run `kwt net start` to proxy any requests to Knative applications (called Knative Services) in a given namespace.

The [`kwt`](https://github.com/k14s/kwt) CLI can be installed to MacOS with Homebrew:

```plain
brew install k14s/tap/kwt
```

Run the helper script to configure and run `kwt net start` proxy services:

```plain
bootstrap-system-knative kwt test-app
bootstrap-system-knative kwt default
```

The first argument to `bootstrap-system-knative kwt` is the namespace when you are deploying your Knative apps.

Provide your sudo root password at the prompt.

The `kwt net start` command launches a new pod `kwt-net` in the `kubecf` namespace, which is used to proxy your traffic into the cluster.

The `kwt` proxy is ready when the output looks similar to:

```plain
...
07:17:27AM: info: KubeEntryPoint: Waiting for networking pod 'kwt-net' in namespace 'kubecf' to start...
...
07:17:47AM: info: ForwardingProxy: Ready!
```

We can now access the `.test-app.example.com` application URLs:

```plain
$ curl http://sample-app-nodejs.test-app.example.com
Hello World!
```

## Rancher Rio

[Rancher](https://rancher.com/)'s [Rio](https://rio.io/) is:

> The MicroPaaS for Kubernetes: Build, test, deploy, scale, and version stateless apps in any Kubernetes cluster.

```plain
bootstrap-kubernetes-demos up --rio
```

The output might look similar to:

```plain
[INFO]  Finding latest release
[INFO]  Using v0.5.0 as release
[INFO]  Downloading hash https://github.com/rancher/rio/releases/download/v0.5.0/sha256sum-amd64.txt
[INFO]  Downloading binary https://github.com/rancher/rio/releases/download/v0.5.0/rio-darwin-amd64
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   607    0   607    0     0    701      0 --:--:-- --:--:-- --:--:--   700
100 72.0M  100 72.0M    0     0   454k      0  0:02:42  0:02:42 --:--:-- 1488k
[INFO]  Verifying binary download
[INFO]  Installing rio to /Users/drnic/Projects/kubernetes/bootstrap-kubernetes-demos/bin/rio
Deploying Rio control plane....
rio controller version v0.5.0 (303f3652) installed into namespace rio-system
Detecting if clusterDomain is accessible...
ClusterDomain is reachable. Run `rio info` to get more info.
Controller logs are available from `rio systemlogs`

Welcome to Rio!

Run `rio run https://github.com/rancher/rio-demo` as an example
```

The `rio` system will download the latest `rio` CLI into `bin/rio`, and will `rio install` into your Kubernetes cluster.

To run the example `rio run` into `default` namespace and view locally with `kwt`:

```plain
rio run https://github.com/rancher/rio-demo
```

Now run `kwt net start` for the `default` namespace in another terminal:

```plain
sudo -E kwt net start --namespace default
```

To view the `rio-demo` URL:

```plain
$ kwt net svc
Services in namespace 'default'

Name                  Internal DNS                                    Cluster IP   Ports
bold-wright0          bold-wright0.default.svc.cluster.local          10.0.11.198  80/tcp
bold-wright0-metrics  bold-wright0-metrics.default.svc.cluster.local  10.0.8.94    9090/tcp
bold-wright0-priv     bold-wright0-priv.default.svc.cluster.local     10.0.6.255   80/tcp
bold-wright0-v0       bold-wright0-v0.default.svc.cluster.local       10.0.12.163  80/tcp
kubernetes            kubernetes.default.svc.cluster.local            10.0.0.1     443/tcp
```

When the rio app is ready:

```plain
$ curl bold-wright0.default.svc.cluster.local
Hi there, I'm running in Rio
```
