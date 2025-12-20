###### Hashicorp Consul set up guide

## Set up cluster

set up a cluster with minikube

> Create cluster with minikube
> 
> ```bash
> minikube start --driver=docker
> ```

>[!NOTE]
> If you do not have helm installed you can find it here
> https://github.com/helm/helm/releases/tag/v4.0.4

## Get helm repository

> Get Hashicorp helm repository
> 
> ```bash
> helm repo add hashicorp https://helm.releases.hashicorp.com
> ```

## With a cluster running

> Sets up a service account in the default namespace and creates a cluster role binding for the service account
> 
> ```bash
> chmod +x ./consul/scripts/get-k8s-values-for-vault-auth-config.sh &&
> ./consul/scripts/get-k8s-values-for-vault-auth-config.sh
> ```

After getting the output of the bash script in the previous command there should be a file called vault-k8s-auth.json in the consul folder

> Creates vault namespace and the pods for vault
> 
> ```bash
> helm install vault hashicorp/vault --create-namespace --namespace vault --values ./consul/helm-values/helm-vault-raft-values.yml
> ```

Now there should have some pods in the vault namespace

> Check the pods are running
> 
> ```bash
> kubectl get pods -n vault
> ```

With the pods running in the vault name space

> Creates a json file with tokens required for accessing the vault
> 
> ```bash
> kubectl exec -i -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json 2>/dev/null | tee ./consul/cluster-keys.json > /dev/null
>```

> [!NOTE]
> 
> In the fallowing command for unsealing the vault in pod vault-0 unseal_keys_b64 value from the json file in /consul/cluster-keys.json

> Unseal vault in pod vault-0
> 
> ```bash
> kubectl exec -n vault vault-0 -- vault operator unseal <inset unseal_keys_b64 key>
> ```

> Makes pods vault-1 and vault-2 join the vault-0 pod
> 
> ```bash
> kubectl exec -n vault -ti vault-1 -- vault operator raft join http://vault-0.vault-internal:8200 && kubectl exec -n vault -ti vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
> ```

> [!NOTE]
> 
> In the fallowing command for unsealing the vault in pod vault-1 unseal_keys_b64 value from the json file in /consul/cluster-keys.json

> Unseal vault-1
> 
> ```bash
> kubectl exec -n vault -ti vault-1 -- vault operator unseal <inset unseal_keys_b64 key>
> ```

> [!NOTE]
> 
> In the fallowing command for unsealing the vault in pod vault-2 unseal_keys_b64 value from the json file in /consul/cluster-keys.json

> Unseal vault-2
> 
> ```bash
> kubectl exec -n vault -ti vault-2 -- vault operator unseal <inset unseal_keys_b64 key>
> ```

## Copy files to pod vault-0

> [!NOTE]
> 
> This /consul/vault-k8s-auth.json file was created by ./consul/scripts/get-k8s-values-for-vault-auth-config.sh

> Copy files to pod vault-0
> 
> ```bash
> kubectl cp -n vault ./consul/policies/consul-server-policy.hcl vault-0:/tmp/consul-server-policy.hcl
> kubectl cp -n vault ./consul/policies/ca-policy.hcl vault-0:/tmp/ca-policy.hcl
> kubectl cp -n vault ./consul/policies/consul-acl-manager-policy.hcl vault-0:/tmp/consul-acl-manager-policy.hcl
> kubectl cp -n vault ./consul/vault-k8s-auth.json vault-0:/tmp/vault-k8s-auth.json
> kubectl cp -n vault ./consul/policies/consul-bootstrap-token-policy.hcl vault-0:/tmp/consul-bootstrap-token-policy.hcl
> ```

## Set up inside the vault-0 pod

> login to vault
> ```bash
>  kubectl exec -it vault-0 -n vault -- /bin/sh
>```
> type 
> ```bash
> vault login
> ```
> then insert the root token from cluster-keys.json
> afterward enable vaults.

> Enable pki in vault-0
> 
> ```bash
> vault secrets enable pki
> ```

> Tune max ttl for pki
> 
> ```bash
> vault secrets tune -max-lease-ttl=87600h pki
> ```

> Enable kv-v2
> 
> ```bash
> vault secrets enable -path=secret kv-v2
> ```

> [!NOTE]
> 
> If you plan on running consul in a different namespace or you plan on changing name and datacenter in consul/helm-values/consul-datacenter-values.yaml you will have to edit consul/scripts/allowed-domains.sh to have the correct values for name, namespace and datacenter
> 
> If you do not plan on making any changes you do not need to run the following command

> get allowed domains as a list out put in consol
> 
> ```bash
> ./consul/scripts/allowed-domains.sh
> ```

> generate a certificate for consul datacenter change the common_name to what you plan on calling you datacenter and the namespace for consul
> 
> common_name format: common_name="datacenter-name.namespace with consul"
> 
> run in the vault
> ```bash
> vault write -field=certificate pki/root/generate/internal common_name="dc1.consul" ttl=87600h
> ```

> Create policies
> run in the vault
> ```bash
> vault policy write consul-server /tmp/consul-server-policy.hcl
> vault policy write ca-policy /tmp/ca-policy.hcl
> vault policy write consul-acl-manager /tmp/consul-acl-manager-policy.hcl
> vault policy write consul-bootstrap /tmp/consul-bootstrap-token-policy.hcl
> ```

> [!NOTE]
> 
> If you needed to run the script consul/scripts/allowed-domains.sh change allowed_domains to the output you got from the script
> 
> Create pki role
> 
> run in the vault
> ```bash
> vault write pki/roles/consul-server allowed_domains="dc1.consul, consul-server, consul-server.consul, consul-server.consul.svc" allow_subdomains=true allow_bare_domains=true allow_localhost=true max_ttl="87600h"
> ```

> Enable kubernetes auth and set the config
> 
> run in the vault
> ```bash
> vault auth enable kubernetes
> vault write auth/kubernetes/config @/tmp/vault-k8s-auth.json
> ```

> [!NOTE]
> 
> if you plan on changing the namespace for consul to something other than consul you will need to change bound_service_account_namespaces to match your namespace for consul
> 
> Create consul-server kubernetes auth role
> 
> run in the vault
> ```bash
> vault write auth/kubernetes/role/consul-server bound_service_account_names=consul-auth-method,consul-connect-injector,consul-gateway-cleanup,consul-gateway-resources,consul-server,consul-server-acl-init,consul-server-acl-init-cleanup,consul-webhook-cert-manager,default bound_service_account_namespaces=consul audience="https://kubernetes.default.svc.cluster.local" policies=consul-server,consul-bootstrap ttl="720h"
> ```

> [!NOTE]
> 
> if you plan on changing the namespace for consul to something other than consul you will need to change bound_service_account_namespaces to match your namespace for consul
> 
> Create consul-client kubernetes auth role
> 
> run in the vault
> ```bash
> vault write auth/kubernetes/role/consul-client bound_service_account_names=consul-auth-method,consul-connect-injector,consul-gateway-cleanup,consul-gateway-resources,consul-server,consul-server-acl-init,consul-server-acl-init-cleanup,consul-webhook-cert-manager,default bound_service_account_namespaces=consul audience="https://kubernetes.default.svc.cluster.local" policies=consul-server ttl="720h"
> ```

> [!NOTE]
> 
> if you plan on changing the namespace for consul to something other than consul you will need to change bound_service_account_namespaces to match your namespace for consul
> 
> Create consul-ca kubernetes auth role
> 
> run in the vault
> ```bash
> vault write auth/kubernetes/role/consul-ca bound_service_account_names=consul-auth-method,consul-connect-injector,consul-gateway-cleanup,consul-gateway-resources,consul-server,consul-server-acl-init,consul-server-acl-init-cleanup,consul-webhook-cert-manager,default bound_service_account_namespaces=consul audience="https://kubernetes.default.svc.cluster.local" policies=ca-policy ttl="720h"
> ```

> [!NOTE]
> 
> if you plan on changing the namespace for consul to something other than consul you will need to change bound_service_account_namespaces to match your namespace for consul
> 
> Create consul-acl-manager kubernetes auth role
> 
> run in the vault
> ```bash
> vault write auth/kubernetes/role/consul-acl-manager bound_service_account_names=consul-auth-method,consul-connect-injector,consul-gateway-cleanup,consul-gateway-resources,consul-server,consul-server-acl-init,consul-server-acl-init-cleanup,consul-webhook-cert-manager,default bound_service_account_namespaces=consul audience="https://kubernetes.default.svc.cluster.local" policies=consul-acl-manager,consul-bootstrap ttl="720h"
> ```

> [!NOTE]
> 
> Please remember to save the output Create a token
> 
> run in the vault
> ```bash
> vault token create -policy="consul-bootstrap" -ttl=720h -orphan -display-name="consul-bootstrap"
> ```

> [!NOTE]
> 
> replace with the token you created before Save the token in kv
> its also recommended to save tge token somewhere you can find it
> 
> run in the vault
> ```bash
> vault kv put secret/consul-bootstrap-token token="<bootstrap-token-value>"
> ```

## Consul namespace set up

> extract vault-ca
> 
> ```bash
> kubectl exec -n vault vault-0 -- vault read -field=certificate pki/cert/ca | tee ./consul/vault-ca.crt
> ```

> Create consul namespace
> 
> ```bash
> kubectl create namespace consul
> ```

> [!NOTE]
> 
> this gets the vault-ca that was extracted from the vault
> 
> Set up vault-ca secret
> 
> ```bash
> kubectl create secret generic vault-ca -n consul --from-file vault.ca=./consul/vault-ca.crt
> ```

> Set up consul pods
> 
> ```bash
> helm install --values ./consul/helm-values/consul-datacenter-values.yaml consul hashicorp/consul --namespace consul --version "1.9.0"
> ```

## Access the consul ui

> [!NOTE]
> 
> use the token that you created in the vault to login on the ui
> 
> Port froward consul
> 
> ```bash
> kubectl port-forward -n consul consul-server-0 8500:8500
> ```

you can find the ui at
> http://localhost:8500/ui/dc1/services


kind --name gamebase load docker-image kms-rewrapper:local

docker exec gamebase-control-plane mkdir -p /etc/kubernetes/manifests/userconfigs


docker cp ./k8s-security-management/Kind-kube-apiserver.yaml gamebase-control-plane:/etc/kubernetes/manifests/kube-apiserver.yaml

docker cp ./vault-kms/userconfigs/. gamebase-control-plane:/etc/kubernetes/manifests/userconfigs/

kubectl annotate namespace kms consul.hashicorp.com/connect-inject="false" --overwrite

kubectl edit mutatingwebhookconfiguration consul-connect-injector

docker exec gamebase-control-plane systemctl restart kubelet

kubectl annotate namespace kms consul.hashicorp.com/connect-inject="false" --overwrite

chown root:root /etc/kubernetes/manifests/userconfigs/encryption-config.yaml
chmod 600 /etc/kubernetes/manifests/userconfigs/encryption-config.yaml 


docker exec -it gamebase-control-plane bash