# SecureSoftwareK8S

###### K8s cluster management for security

## DEVS

* Jens
* Andreas
* Emil

## Purpose

This Project was originally a school compulsory project at EASV(erhvervsakademi sydvest | business academy southwest).
This project where made for purely educational purposes and should not be used for any monetary gains.
It is now being used for Testing and managing a kubernetes cluster in regards to security and isolation of services, as an exams project.

## Original Project

This Project is a fork of an older project named GameBAse(<https://github.com/emil476m/GameBase>), it is not meant to expand upon this project in terms of features or other ux enhancement. Instead the goal is to use it as an existing code base to make a k8s(kubernetes) cluster around, with a focus on security.



## Run

This section will be updated as the project goes on.

For now you can run these commands in this order

Please setup rest encryption for k8s secrets first [Guide](k8s-rest-encryption.md)

if you want to try kms v2 setup for k8s rest encryption please follow this guide first [Guide](key-managment-system-set-up.md)

Please set up consul first here is a guide for it: [Guide](Consul-set-up.md)


> Create k8s namespaces
>
>```bash
> kubectl apply -f ./k8s-namespace/
>```

>[!Note]
> 
> now that you have created the namespaces
> please go follow this guide on setting up acl in consul 
>  [Guide](Consul-acl-setup.md)

> Create database secrets
>
>```bash
> kubectl create secret generic postgres-secret -n database   --from-literal=POSTGRES_DB='GameBaseDb'   --from-literal=username='postgres'   --from-literal=password='Your$ecureP@ssw0rd!'
>```
>
>```bash
> kubectl create secret generic gamebase-db-secret -n gamebase   --from-literal=pgconn='Host=postgres.database.svc.cluster.local;Port=5432;Database=GameBaseDb;Username=postgres;Password=Your$ecureP@ssw0rd!;SSL Mode=Disable;'
>```

# Set up frontend, gateway and Consul api gateway
>
> ```bash
> docker build -t frontend:local -f ./frontend/Dockerfile .
> minikube image load frontend:local
> docker build -t gateway:local -f ./gateway/Dockerfile .
> minikube image load gateway:local
> ```

> Extract the certificates from the consul vault
> 
> ```bash
> kubectl cp consul-server-0:vault/secrets/servercert.crt ./consul/gateway.crt -n consul -c consul
> kubectl cp consul-server-0:vault/secrets/servercert.key ./consul/gateway.key -n consul -c consul
> ```

> Create a certificate secret for the consul api gateway
> 
> ```bash
> kubectl create secret tls consul-server-cert -n consul --cert=./consul/gateway.crt --key=./consul/gateway.key
> ```

> Create frontend config secret
> 
> ```bash
> kubectl create secret generic frontend-config-secret --from-file=config.json=./frontend-config/config.json -n gamebase
> ```

## Observability suite(setup is optional)
> This is optional, it will allow you to observe the traffic in the service mesh.
> it uses prometheus and grafana for metrics and visualization along with loki and alloy for logs.
>
> Please follow this setup guide for the observability suite [Guide](observability-suite.md)

## Apply service intentions and set up consul api gateway

>[!NOTE]
> if needed you can update your Kubernetes api gateway CRDs by using this command
> this installs version v1.2.1 of the gateway api which allows use of gateway.networking.k8s.io/v1
> ```bash
> kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
>```

> Apply consul api gateway
> 
> ```bash
> kubectl apply -f ./consul/consul-gateway.yaml
> ```

>[!NOTE]
> 
> Make sure that you run the following command to allow the Envoy sidecars to communicate with the different services
> 
> Apply service intentions
> 
> ```bash
> kubectl apply -f ./consul/intentions.yaml
> ```

### Create gamebase pods and database pod
> Create k8s pods
>
>```bash
> kubectl apply -f ./k8s/
>```


> View pods for gamebase and database namespaces
>
>```bash
> kubectl get pods -n gamebase && kubectl get pods -n database
>```

>[!NOTE]
> this is a command containing placeholder data for creating the tables needed in the database
>
> ```bash
> kubectl cp ./database-config/create.sql postgres-0:/tmp/init.sql -n database -c postgres
> kubectl exec -n database postgres-0 -c postgres -- psql -U postgres -d GameBaseDb -f /tmp/init.sql
> ```


>[!NOTE]
> 
> If you want to access the frontend you can do so by using the following command
> remember to use https since the consul api gateway uses tls
> 
> ```bash
> minikube service api-gateway -n consul --url
> ```

> View all resources for gamebase and database namespaces(remove the -o wide flag for less details)
>
>```bash
> kubectl get all -n gamebase -o wide && kubectl get all -n database -o wide
>```

> If you want a view over all pods on your system
>
>```bash
> kubectl get pods --all-namespaces -o wide
>```

> To see the page use the following command, make sure to use http on the shown url
> ```
> minikube service api-gateway -n consul --url
>```
 

> If you want to confirm encryption at rest is working for secrets you can use the following command and search for GameBaseDb then you will see the value for key1 is encrypted
>
>```bash
> minikube ssh
>```

> [!WARNING]
> Please be aware that its a big file, so its not recommended to use a cmd editor that reads the whole file at once like cat, since it will spam your terminal

> use this command to open the etcd db file in vi editor(vi dosnt show the whole file at once so its better for this usecase)
> ```bash
> sudo vi /var/lib/minikube/etcd/member/snap/db
> ```
> then search for GameBaseDb by typing /GameBaseDb and hitting enter
> It should says pattern not found, or if its not encrypted you will see the secrets in plain text
> if it is encrypted you can try to search for key1, postgres-secret or secretbox and then it should show you some encrypted values
> you can use :qa to exit vi

> Remove (deleting a namespace will also remove all resources within it)
>
>```bash
> kubectl delete -f ./k8s/ && kubectl delete namespace database && kubectl delete namespace gamebase
>```

> Deletes the minikube cluster
>
>```bash
> minikube delete
>```

> Removes all extra configs from minikube (only needed if you want to start a new cluster without the security features or other extra features)
>
>```bash
> minikube config unset extra-config
>```


