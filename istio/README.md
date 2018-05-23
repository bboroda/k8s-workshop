

# ReactiveOps Kubernetes Istio Workbook
This assumes you already have a working Kubernetes cluster version 1.9 or higher

## Download and install Istio
```
export ISTIO_VERSION=0.7.1
curl -L https://git.io/getLatestIstio | sh -
export PATH=$PWD/istio-$ISTIO_VERSION/bin:$PATH
cd istio-$ISTIO_VERSION/
```

## Once you have created your cluster, you need to make your user a cluster admin
```
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)
```

## Configure Istio with MTLS in your cluster
```
kubectl apply -f install/kubernetes/istio-auth.yaml
```
Example:
https://github.com/reactiveops/k8s-workshop/blob/master/istio/examples/istio-auth.yaml

```
kubectl apply -f install/kubernetes/istio-auth.yaml
```
## Install Sidecar Injector
```
install/kubernetes/webhook-create-signed-cert.sh \
    --service istio-sidecar-injector \
    --namespace istio-system \
    --secret sidecar-injector-certs

kubectl apply -f install/kubernetes/istio-sidecar-injector-configmap-debug.yaml

cat istio-$ISTIO_VERSION/install/kubernetes/istio-sidecar-injector.yaml | \
     istio-$ISTIO_VERSION/install/kubernetes/webhook-patch-ca-bundle.sh > \
     istio-$ISTIO_VERSION/install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml

kubectl apply -f install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml
```

##### Create and Label namespace so the injection works
```
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
```

## Deploy Book Info Application

##### Set context to use `bookinfo` namespace

#### Apply bookinfo manifests
```
kubectl apply -f samples/bookinfo/kube/bookinfo.yaml
```
https://github.com/istio/istio/blob/master/samples/bookinfo/kube/bookinfo.yaml

## ** Quickstart ends here **

### Verify MTLS
```
kubectl get configmap istio -o yaml -n istio-system | grep authPolicy | head -1
```
##### Exec into sidecar container in product page pod
```
PRODUCTPAGEPOD=$(kubectl get pods --selector=app=productpage -o=jsonpath='{.items[*].metadata.name}')
kubectl exec -it $PRODUCTPAGEPOD -c istio-proxy /bin/bash
```
##### Curl using cert
This is only available when istio injector is configured in debug mode
```
curl https://details:9080/details/0 -v --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
```
If the request works then we know the certs are being used and inter pod traffic is encrypted

#### Find LB ip address
```
kubectl get services --all-namespaces
kubectl get ingress
```

## Dynamic Routing with Istio
### Route all traffic to V1 of Book Info Reviews Service

```
kubectl apply -f samples/bookinfo/kube/route-rule-all-v1.yaml
```
https://github.com/istio/istio/blob/master/samples/bookinfo/kube/route-rule-all-v1.yaml

### Content based routing for V2 of the Book Info Reviews Service
```
kubectl apply -f samples/bookinfo/kube/route-rule-reviews-test-v2.yaml
```
https://github.com/istio/istio/blob/master/samples/bookinfo/kube/route-rule-reviews-test-v2.yaml

### AB Test V2 and V3 of Book Info Reviews Service
```
kubectl apply -f samples/bookinfo/kube/route-rule-reviews-v2-v3.yaml
```
https://github.com/istio/istio/blob/master/samples/bookinfo/kube/route-rule-reviews-v2-v3.yaml

## Mixer Telemetry and Prometheus

#### Add Prometheus
```
kubectl apply -f install/kubernetes/addons/prometheus.yaml
```

#### Add Telemetry spec for Mixer and Prometheus
```
kubectl apply -f https://raw.githubusercontent.com/reactiveops/k8s-workshop/master/istio/new_telemetry.yml
```
#### Get Prometheus pod
```
kubectl get pod -n istio-system | grep prometheus
```
#### View Prometheus Dashboard
```
PROMETHEUSPOD=$(kubectl get pods -n istio-system --selector=app=prometheus -o jsonpath='{.items[*].metadata.name}')
kubectl -n istio-system port-forward $PROMETHEUSPOD 8080:9090
```

## Istio Dashboard in Grafana

```
kubectl apply -f install/kubernetes/addons/grafana.yaml
```
### Get Grafana pod
```
GRAFANAPOD=$(kubectl get pods -n istio-system --selector=app=grafana -o jsonpath='{.items[*].metadata.name}')
kubectl -n istio-system port-forward $GRAFANAPOD 8080:3000
```

# Istio Docs: 
https://istio.io/docs/welcome/

# More resource: 
https://github.com/retroryan/istio-workshop


