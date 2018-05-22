#!/bin/bash
set -x

# quickstart.sh
# Create cluster and install istio and helm to prepare for the k8s workshop walk through

KUBERNETES_VERSION="1.10.2-gke.1"
GKE_ZONE="us-west1-b"
NETWORK="default"
CLUSTER_NAME="istio-demo"
ISTIO_VERSION="0.7.1"

cd $HOME

# Create cluster
gcloud beta container \
    --project $GOOGLE_CLOUD_PROJECT \
    clusters create $CLUSTER_NAME \
    --zone $GKE_ZONE \
    --no-enable-basic-auth \
    --cluster-version $KUBERNETES_VERSION \
    --machine-type "n1-standard-1" \
    --image-type "COS" \
    --disk-size "100" \
    --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    --num-nodes "3" \
    --network $NETWORK \
    --enable-cloud-logging \
    --enable-cloud-monitoring \
    --subnetwork $NETWORK \
    --enable-autoscaling \
    --min-nodes "3" \
    --max-nodes "6" \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing \
    --enable-autorepair

# Configure kubectl to connect to this cluster
gcloud container clusters get-credentials $CLUSTER_NAME --zone $GCP_ZONE --project $GOOGLE_CLOUD_PROJECT

# Install and configure Helm. This is required to install Istio.
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz
tar zxfv helm-v2.9.1-linux-amd64.tar.gz
cp linux-amd64/helm /usr/local/bin

kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --upgrade --service-account tiller

# Install Istio in cloudshell
curl -L https://git.io/getLatestIstio | sh -

# Install Istio in cluster and enable all features
helm install \
    istio istio-$ISTIO_VERSION/install/kubernetes/helm/istio \
    --set mtls.enabled=true \
    --set sidecar-injector.enabled=true \
    --set prometheus.enabled=true \
    --set servicegraph.enabled=true \
    --set zipkin.enabled=true \
    --namespace istio-system

echo =============================================== 
echo "export PATH=$PWD/istio-$ISTIO_VERSION/bin:$PATH"
echo ===============================================
