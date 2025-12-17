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
>
>```bash
>kubectl apply -f ./k8s-namespace/
>```

> create database secrets
>
>```bash
>kubectl create secret generic postgres-secret -n database   --from-literal=POSTGRES_DB='GameBaseDb'   --from-literal=username='postgres'   --from-literal=password='Your$ecureP@ssw0rd!'
>```

> create k8s pods
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

If you want a view over all pods on your system
>
>```bash
>kubectl get pods --all-namespaces -o wide
>```

> Remove (deleting a namespace will also remove all resources within it)
>
>```bash
> kubectl delete -f ./k8s/ && kubectl delete namespace database && kubectl delete namespace gamebase
>```

