> This is some steps to enable encryption at rest for secrets in minikube(k8s) by using key managment system

>[!WARNING]
> 
> This might cause your minikube to hang and crash on start up.
> 
> if you successfully get it to start up do not delete kms vault because then you kubernetes environment can never decrypt the existing secrets
> 

>```bash
>minikube start
>```


> With minikube running we need to copy the encryption config
> 
> ```bash
> minikube ./vault-kms/encryption-config.yaml minikube:/tmp/encryption-config.yaml
> ```


> SSH into the minicube instance
> 
> ```bash
> minikube ssh
>```

 
> Make kms directory in minikube
> 
> ```bash
> sudo mkdir -p /var/kms/ && sudo chmod 777 /var/kms
> ```

> Exit minikube
> 
> ```bash
>  exit
> ```


## Set up Kms vault 


> Get Hashicorp helm repository if you do not have it
>
> ```bash
> helm repo add hashicorp https://helm.releases.hashicorp.com
> ```

> Install the hashicorp vault with helm
> ```bash
> helm install vault-kms hashicorp/vault --create-namespace --namespace kms --values ./vault-kms/vault-kms-values.yaml
> ```

> Copy policies in to vault
> 
> ```bash
> kubectl cp -n kms ./vault-kms/policies/kms-policy.hcl vault-kms-0:/tmp/kms-policy.hcl
> ```

> Creates a json file with tokens required for accessing the vault
> 
>  the keys gets saved in v/ault-kms/cluster-keys
>
> ```bash
> kubectl exec -i -n kms vault-kms-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json 2>/dev/null | tee ./vault-kms/cluster-keys.json > /dev/null
> ```


> [!NOTE]
>
> In the fallowing command for unsealing the vault in pod vault-0 unseal_keys_b64 value from the json file in /vault-kms/cluster-keys.json

> Unseal vault in pod vault-0
>
> ```bash
> kubectl exec -n kms vault-kms-0 -- vault operator unseal
> ```

> Makes pods vault-1 and vault-2 join the vault-0 pod
>
> ```bash
> kubectl exec -n kms -ti vault-kms-1 -- vault operator raft join http://vault-kms-0.vault-kms-internal:8200 && kubectl exec -n kms -ti vault-kms-2 -- vault operator raft join http://vault-kms-0.vault-kms-internal:8200
> ```

> [!NOTE]
>
> In the fallowing command for unsealing the vault in pod vault-1 unseal_keys_b64 value from the json file in /vault-kms/cluster-keys.json

> Unseal vault-1
>
> ```bash
> kubectl exec -n kms -ti vault-kms-1 -- vault operator unseal <inset unseal_keys_b64 key>
> ```

> [!NOTE]
>
> In the fallowing command for unsealing the vault in pod vault-2 unseal_keys_b64 value from the json file in /vault-kms/cluster-keys.json

> Unseal vault-2
>
> ```bash
> kubectl exec -n kms -ti vault-kms-2 -- vault operator unseal <inset unseal_keys_b64 key>
> ```

>login to vault
> ```bash
>  kubectl exec -it vault-kms-0 -n kms -- /bin/sh
>```

> type
> ```bash
> vault login
> ```

> then insert the root token from /vault-kms/cluster-keys.json

> enable kubernetes auth
> run in vault
> ```bash
> vault auth enable kubernetes
> vault write auth/kubernetes/config  kubernetes_host="https://kubernetes.default.svc.cluster.local" disable_iss_validation=true
>```

> Set up vault policy
> run in vault
> ```bash
> vault policy write vault-kms-policy /tmp/kms-policy.hcl
>```

> Enable transit in vault
> run in vault
> ```bash
> vault secrets enable transit
> vault write -f transit/keys/k8s-kek
> ```

> Set up kubernetes auth role
> run in vault
> ```bash
> vault write auth/kubernetes/role/vault-kms bound_service_account_names=vault-kms bound_service_account_namespaces=kms audience="https://kubernetes.default.svc.cluster.local" policies=vault-kms-policy ttl=24h
> ```

> Enable vault audit logging
> run in vault
> ```bash
> vault audit enable file file_path=/vault/logs/audit.log
> ```

> Exit vault
> run in vault
> ```bash
> exit
> ```


> Build Docker image of python rewrapper
> 
> ```bash
> docker build -t kms-rewrapper:local -f ./vault-kms/python-scripts/Dockerfile.yaml .
> ```

> Load the docker image into minikube
> ```bash
> minikube image load kms-rewrapper:local
>  ```

> Apply the kms manifest
> 
> ```bash
> kubectl apply -f ./kmsv2-manifest-k8s.yaml
> ```

> Check if kms pods are running
> 
> ```bash
> kubectl get pods -n kms
> ```

> Stop minikube
> 
> ```bash
> minikube stop
> ```

> start minikube with mounts and extra config
> 
> ```bash
> minikube start --mount --mount-string="./vault-kms/minikubekms-files:/var/kms" --extra-config=apiserver.encryption-provider-config=/var/kms/encryption-config.yaml
> ````

> Test secret rotation
> 
> ```bash
> kubectl get secrets --all-namespaces -o json | kubectl replace -f -
>```
