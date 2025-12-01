# SecureSoftwareK8S
###### K8s cluster management for security

## DEVS
* Jens
* Andreas
* Emil


## Purpose
This Project was orignally a school compulsery project at EASV(erhvervsakademi sydvest | business academy southwest).
This project where made for purely educational purposes and should not be used for any monetary gains.
It is now being used for Testing and managing a kubernetes cluster in regards to security and isolation of services, as an exams project.

## Origina Project
THis Project is a fork of an older project named GameBAse(https://github.com/emil476m/GameBase), it is not meant to exspand upon this project in terms of features or other ux enhancement. Insted the goal is to use it as an existing code base to make a k8s(kuberneties) cluster around, with a focus on security.

## Run
This section will be updated as the project goes on.

For now you can 

> set up current
>```bash
>kubectl apply -f ./search-engine-manifest.k8s.yml 
>```

> View pods
>```bash
> kubectl get all
>```

> Remove 
>```bash
>kubectl delete -f ./search-engine-manifest.k8s.yml 
>```