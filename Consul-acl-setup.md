## Set up ACL policies and roles in Consul


> Copy files to consul server
>
> ```bash
> kubectl cp -n consul ./consul/policies/consul-postgres-ACL-policy.hcl consul-server-0:/tmp/consul-postgres-ACL-policy.hcl
> kubectl cp -n consul ./consul/policies/consul-gamebase-ACL-policy.hcl consul-server-0:/tmp/consul-gamebase-ACL-policy.hcl
>```

> Make an interactive shell with the consul server
>
> ```bash
> kubectl exec -it consul-server-0 -n consul -- /bin/sh 
> ```


>[!NOTE]
> The following commands are run in the interactive shell of the consul server
> you will need to use the token you created in the vault when you see <bootstrap-token>


> export the bootstrap token so you can run the needed commands
>
> run in consul server
>
> ```bash
> export CONSUL_HTTP_TOKEN=<BOOTSTRAP_TOKEN>
> ```


>[!NOTE]
>
> you need to save the secret_id_token
>
> Set up policy and token for gamebase services
>
> run in consul server
>
> ```bash
> consul acl policy create -name gamebase-services -rules @/tmp/consul-gamebase-ACL-policy.hcl
> consul acl token create -description "gamebase services" -policy-name gamebase-services
> ```

>[!NOTE]
>
> you need to save the secret_id_token
>
>Create the policy and token for the database
>
> run in consul server
>
> ```bash
> consul acl policy create -name postgres-connect -rules @/tmp/consul-postgres-ACL-policy.hcl
> consul acl token create -description "postgres connect" -policy-name postgres-connect
> ```

> Set up acl roles
>
> run in consul server
>
> ```bash
> consul acl binding-rule create -method consul-k8s-auth-method -bind-type policy -bind-name postgres-connect -selector 'serviceaccount.namespace == "database" and serviceaccount.name == "postgres"'
> consul acl binding-rule create -method consul-k8s-auth-method -bind-type policy -bind-name gamebase-services -selector 'serviceaccount.namespace == "gamebase"'
> ```

## Set up Secrets in the kubernetes namespaces

>[!NOTE]
>
> you will need the secret_id_token from the acl token you created in consul for the gamebase services policy
>
>  replace <SECRET_ID_FROM_CONSUL> with your secret token id for the gamebase services policy
>
> Create consul-acl secret in gamebase namespace
>
> ```bash
>   kubectl create secret generic consul-acl -n gamebase --from-literal=token='<SECRET_ID_FROM_CONSUL>'
> ```


>[!NOTE]
>
> you will need the secret_id_token from the acl token you created in consul for the postgres connect policy
>
>  replace <SECRET_ID_FROM_CONSUL> with your secret token id for the postgres connect policy
>
> Create consul-acl secret in database namespace
>
> ```bash
>   kubectl create secret generic consul-acl -n database --from-literal=token='<SECRET_ID_FROM_CONSUL>'
> ```