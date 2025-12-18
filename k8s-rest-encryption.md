
>start by creating a file named database-security-config.k8s.yaml in the k8s-security-management folder with the following content:
> ```yaml
> apiVersion: apiserver.config.k8s.io/v1
> kind: EncryptionConfiguration
> resources:
>  - resources:
>     - secrets
>    providers:
>      - secretbox:
>        keys:
>          - name: key1
>            secret: <your secret-base64-encoded-key-here>
>      - identity: {}
> ```

> in the file k8s-security-management/database-security-config.k8s.yaml replace <your secret-base64-encoded-key-here> with your own key
> you can use this command to generate a base64 encoded 32 byte key
>
>```bash
>head -c 32 /dev/urandom | base64
>```

> This is some steps to enable encryption at rest for secrets in minikube(k8s). first start by making sure minikue is running
>
>```bash
>minikube start
>```



> First we need to copy our apiserver manifest and ancryption config to minikube
>
>```bash
>minikube cp k8s-security-management/database-security-config.k8s.yaml minikube:/tmp/encryption-config.yaml && \
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
> chmod 644 gives read access to everyone and write access to owner(user/the one who executes the command) only
> chmod 600 gives read and write access to owner(user/the one who executes the command) only
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
> minikube stop && minikube start
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