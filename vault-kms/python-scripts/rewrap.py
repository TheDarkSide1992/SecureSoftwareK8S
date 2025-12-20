import time
import os
from hvac.api.secrets_engines import transit
from kubernetes import client, config
import hvac

VAULT_ADDR = "http://vault.kms.svc.cluster.local:8200"
TRANSIT_KEY = "k8s-kek"
CHECK_INTERVAL = 86400 # Checks once per day


def get_vault_client():
    config.load_incluster_config()
    v1 = client.CoreV1Api()

    namespace = os.getenv("POD_NAMESPACE", "kms")
    sa_name = os.getenv("SERVICE_ACCOUNT_NAME", "vault-kms")
    vault_addr = os.getenv("VAULT_ADDR", "http://vault-kms.kms.svc.cluster.local:8200")
    vault_role = os.getenv("VAULT_ROLE", "vault-kms")

    token_request_body = client.V1TokenRequest(
        spec=client.V1TokenRequestSpec(
            audiences=["https://kubernetes.default.svc.cluster.local"],
            expiration_seconds=600 
        )
    )

    token_response = v1.create_namespaced_service_account_token(
        name=sa_name,
        namespace=namespace,
        body=token_request_body
    )

    jwt = token_response.status.token

    vault_client = hvac.Client(url=vault_addr)
    vault_client.auth.kubernetes.login(
        role=vault_role,
        jwt=jwt
    )

    return vault_client

def rotate_and_sync_etcd():
    """Binds Vault rotation with Kubernetes etcd updates"""
    try:
        vault_client = get_vault_client()
        k8s_api = client.CoreV1Api()

        vault_client.secrets.transit.rotate_key(name=TRANSIT_KEY)

        secrets = k8s_api.list_secret_for_all_namespaces()

        for secret in secrets_list.items:
            try:
                k8s_api.replace_namespaced_secret(
                    name=secret.metadata.name,
                    namespace=secret.metadata.namespace,
                    body=secret
                )
            except Exception:
                pass
        del secrets_list

        print(f"[{time.ctime()}] 90-day rotation and etcd sync complete.")

    except Exception as e:
        print(f"[{time.ctime()}] Critical Error in rotation loop")

if __name__=="__main__":
    print("KMS Rewrapper Sidecar started...")
    while True:
        rotate_and_sync_etcd
        # Sleep for 24 hours before checking again
        time.sleep(CHECK_INTERVAL)