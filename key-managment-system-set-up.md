> This is some steps to enable encryption at rest for secrets in minikube(k8s) by using key managment system

>[!WARNING]
> 
> if you want to use this you will need to create a seprate docker container for the vault would cause the minikube to not start when encryption is enabled  so moving it to a separate container is a good idea
> 
> This might cause your minikube to hang and crash on start up.
> 
> if you successfully get it to start up do not delete kms vault because then you kubernetes environment can never decrypt the existing secrets

>```bash
>minikube start
>```

> create vault ca
> 
> ```bash
> openssl genrsa -out ./vault-kms/vault-server-certs/ca.key 2048
> openssl req -x509 -new -nodes -key ./vault-kms/vault-server-certs/ca.key -sha256 -days 3650 -out ./vault-kms/vault-server-certs/ca.crt -subj "/CN=Vault-Internal-CA" -config ./vault-kms/vault-server-certs/ca.cnf -extensions v3_ca
> ```

> Create vault server certs
> 
> ```bash
> openssl req -new -newkey rsa:2048 -nodes -keyout ./vault-kms/vault-server-certs/vault.key -out ./vault-kms/vault-server-certs/vault.csr -subj "/CN=host.minikube.internal"
> openssl x509 -req -in ./vault-kms/vault-server-certs/vault.csr -CA ./vault-kms/vault-server-certs/ca.crt -CAkey ./vault-kms/vault-server-certs/ca.key -CAcreateserial -out ./vault-kms/vault-server-certs/vault.crt -days 365 -sha256 -extfile ./vault-kms/vault-server-certs/san.cnf -extensions v3_req
>```

> Make certs on your host for the vault
> 
> ```bash
> cd ./vault-kms/vault-server-certs
> openssl genrsa -out client.key 2048
> openssl req -new -key client.key -subj '/CN=vault-kms-provider' -out client.csr
> openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365 -sha256 -extfile clientauth.cnf -extensions v3_client_auth
> cd ./../..
> ```

## Set up Kms vault 


>[!NOTE]
> you should never use this in production
> Docker vault container setup
> ```bash
> docker run -d --cap-add=IPC_LOCK --name vault-kms-backend -p 8200:8200 -p 8201:8201  -v ./vault-kms/vault-config.json:/vault/config/local.json -v ./vault-kms/vault-server-certs:/vault/certs -v ./vault-kms/vault-data:/vault/file  hashicorp/vault server
> ```

> Copy policy file to docker and minikube ca

> ```bash
> docker cp ./vault-kms/policies/kms-policy.hcl vault-kms-backend:/tmp/kms-policy.hcl
> ```


> Docker interactive session
> 
>```bash
> docker exec -it vault-kms-backend sh
>```


> Set up local vault url for vault set up
> ```bash
>  export VAULT_CACERT='/vault/certs/vault.crt'
>  export VAULT_ADDR='https://127.0.0.1:8200'
>```

> Initialize vault remember to save the output of this
> you can change the key-shares and key-threshold to whatever you like
>
> ```bash
> vault operator init -tls-skip-verify -key-shares=1 -key-threshold=1
> ```

> Unseal the vault
> 
> use the unseal_keys from the init output
> 
> ```bash
> vault operator unseal <inset unseal key>
> ```

> login to the vault
> use the root_token from the init output
> ```bash
> vault login <root_token>
> ```

> Enable cert auth in vault
> 
> ```bash
> vault auth enable cert
> ```

> Set up vault policy
> run in vault
> ```bash
> vault policy write vault-kms-policy /tmp/kms-policy.hcl
>```

> Enable cert auth in vault
>
> ```bash
> vault write auth/cert/certs/vault-internal-ca certificate=@/vault/certs/ca.crt allowed_common_names="vault-kms-provider" display_name="kms-auth" policies="vault-kms-policy" ttl=768h
> ```


> Enable transit in vault
> run in vault
> ```bash
> vault secrets enable transit
> vault write -f transit/keys/k8s-kek
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


> With minikube running we need to copy the encryption config
>
> ```bash
> minikube cp vault-kms/minikube-kms-files/encryption-config.yaml minikube:/tmp/encryption-config.yaml
> minikube cp vault-kms/kms-v2-manifest-k8s.yaml minikube:/tmp/kms-v2-manifest-k8s.yaml
> minikube cp vault-kms/vault-server-certs/ca.crt minikube:/tmp/vault-ca.crt
> minikube cp vault-kms/vault-server-certs/client.crt minikube:/tmp/client.crt
> minikube cp vault-kms/vault-server-certs/client.key minikube:/tmp/client.key
> minikube cp vault-kms/kube-apiserver.yaml minikube:/tmp/kube-apiserver.yaml
> ```


> SSH into the minicube instance
>
> ```bash
> minikube ssh
>```

> Make vault ca chart dir
> 
> ```bash
> sudo mkdir -p /var/vault-cert
> sudo chmod 755 /var/vault-cert
> ```


> At this point we move the encryption config 
>
>```bash
> sudo mv /tmp/encryption-config.yaml /etc/kubernetes/encryption-config.yaml && \
> sudo mv /tmp/kms-v2-manifest-k8s.yaml /etc/kubernetes/manifests/kms-v2-manifest-k8s.yaml && \
> sudo mv /tmp/vault-ca.crt /var/vault-cert/vault-ca.crt && \
> sudo mv /tmp/client.crt /var/vault-cert/client.crt && \
> sudo mv /tmp/client.key /var/vault-cert/client.key && \
> sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
>```

> make the right perms for the files
> ```bash
> sudo chown root:root /etc/kubernetes/manifests/kms-v2-manifest-k8s.yaml && \
> sudo chmod 644 /etc/kubernetes/manifests/kms-v2-manifest-k8s.yaml
> sudo chown root:root /etc/kubernetes/encryption-config.yaml && \
> sudo chmod 600 /etc/kubernetes/encryption-config.yaml && \
> sudo sudo chown root:root /var/vault-cert/vault-ca.crt && \
> sudo chmod 644 /var/vault-cert/vault-ca.crt && \
> sudo sudo chown root:root /var/vault-cert/client.crt && \
> sudo chmod 644 /var/vault-cert/client.crt && \
> sudo sudo chown root:root /var/vault-cert/client.key && \
> sudo chown root:root /etc/kubernetes/manifests/kube-apiserver.yaml && \
> sudo chmod 644 /etc/kubernetes/manifests/kube-apiserver.yaml && \
> sudo chmod 644 /var/vault-cert/client.key
> ```


> Exit minikube
>
> ```bash
> exit
> ```

> Stop minikube
> 
> ```bash
> minikube stop && minikube start
> ```

> Test secret rotation
> 
> ```bash
> kubectl get secrets --all-namespaces -o json | kubectl replace -f -
>```
