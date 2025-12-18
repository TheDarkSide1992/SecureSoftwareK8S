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

Please set up consul first here is a guid for it: [Guid](Consul-set-up.md)

> create k8s namespaces

> This is some steps to enable encryption at rest for secrets in minikube(k8s). first start by making sure minikue is running
>
>```bash
>minikube start
>```

> in the file k8s-security-management/database-security-config.k8s.yaml replace <your secret-base64-encoded-key-here> with your own key
> you can use tihs command to generate a base64 encoded 32 byte key
>
>```bash
>head -c 32 /dev/urandom | base64
>```

> First we need to copy our apiserver manifest and ancryption config to minikube
>
>```bash
>minikube cp k8s-security-management/encryption-config.yaml minikube:/tmp/encryption-config.yaml && \
>minikube cp k8s-security-management/kube-apiserver.yaml minikube:/tmp/kube-apiserver.yaml
>```

> Now we ssh into minikube
>
>```bash
>minikube ssh
>```

> At this point we move the encryption config and replace the apiserver manifest with our modified one(this is the paths for minikube might differ for other k8s installations)
>
>```bash
>sudo mv /tmp/encryption-config.yaml /etc/kubernetes/encryption-config.yaml && \
>sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
>```

> At this point we just need to set some access rights for the files and then we can exit minikube ssh
> chmod 644 gives read access to everyone and write access to owner only
> chmod 600 gives read and write access to owner only
>
>```bash
>sudo chown root:root /etc/kubernetes/manifests/kube-apiserver.yaml && \
>sudo chmod 644 /etc/kubernetes/manifests/kube-apiserver.yaml && \
>sudo chown root:root /etc/kubernetes/encryption-config.yaml && \
>sudo chmod 600 /etc/kubernetes/encryption-config.yaml
>```

> While minikube should restart the apiserver automatically once it detects changes to its manifest you can also just exit and restart minikube to be sure
>
>```bash
>exit 
>```
> After you exit minikube ssh you can restart minikube with
> ```bash
>minikube stop && minikube start
> ```

> First please confirm your current kubernetes context(since some security features wont work in docker desktop k8s)
>
>```bash
>kubectl config current-context
>```

> You can switch to minikube context with this command(if you are using minikube or just replace minikube with your desired context name)
>
>```bash
>kubectl config use-context minikube
>```

> Create k8s namespaces
>
>```bash
>kubectl apply -f ./k8s-namespace/
>```

> Create database secrets
>
>```bash
>kubectl create secret generic postgres-secret -n database   --from-literal=POSTGRES_DB='GameBaseDb'   --from-literal=username='postgres'   --from-literal=password='Your$ecureP@ssw0rd!'
>```

> Create k8s pods
>
>```bash
>kubectl apply -f ./k8s/
>```

> View pods for gamebase and database namespaces
>
>```bash
> kubectl get pods -n gamebase && kubectl get pods -n database
>```

> View all resources for gamebase and database namespaces(remove the -o wide flag for less details)
>
>```bash
> kubectl get all -n gamebase -o wide && kubectl get all -n database -o wide
>```

> If you want a view over all pods on your system
>
>```bash
>kubectl get pods --all-namespaces -o wide
>```

> If you want to confirm encryption at rest is working for secrets you can use the following command and search for GameBaseDb then you will see the value for key1 is encrypted
>
>```bash
> minikube ssh && vi /var/lib/minikube/etcd/member/snap/db
>```

> Remove (deleting a namespace will also remove all resources within it)
>
>```bash
> kubectl delete -f ./k8s/ && kubectl delete namespace database && kubectl delete namespace gamebase
>```

> Deletes the minikube cluster
>
>```bash
>minikube delete
>```

> Removes all extra configs from minikube (only needed if you want to start a new cluster without the security features or other extra features)
>
>```bash
> minikube config unset extra-config
>```


