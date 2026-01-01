### This is a guide on setting up an observability suite for traffic within the service mesh


## Prerequisites
- A running Kubernetes cluster with Consul service mesh installed and configured.
- Helm installed on your local machine.
- kubectl configured to interact with your Kubernetes cluster.


> Get the Prometheus and Grafana Helm charts
> 
> ```bash
>  helm repo add grafana https://grafana.github.io/helm-charts
>  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
> ```

> Update Helm repositories
> ```bash
> helm repo update
> ```

> Install Prometheus, Grafana and Loki using Helm
> 
> ```bash
> helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --values ./observability/monitoring.yaml
> helm install loki grafana/loki -n monitoring --values ./observability/loki-values.yaml
> helm install alloy grafana/alloy -n monitoring --values ./observability/alloy-values.yaml
> ```

> Set up PodMonitoring for pods in the Consul service mesh
> ```bash
> kubectl apply -f ./observability/pod-monitor/pod-monitor.k8s.yaml
> ```

> Check that the pods are running in the monitoring namespace
> 
>  ```bash
> kubectl get pods -n monitoring
> ```


> To access Grafana and Prometheus dashboards, you can port-forward the services to your local machine
>
> ```bash
> kubectl port-forward svc/prometheus-grafana -n monitoring 80:80
> kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
> ```

> Get grafana admin credentials
> 
> ```bash
> kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
> kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-user}" | base64 --decode ; echo
> ```


