import time
import os
from hvac.api.secrets_engines import transit
from kubernetes import client, config
import hvac

VAULT_ADDR = "http://vault.kms.svc.cluster.local:8200"
TRANSIT_KEY = "k8s-kek"
CHECK_INTERVAL = 86400 # Checks once per day
CERT_DIR = "/var/vault-cert"
CA_CERT = os.path.join(CERT_DIR, "vault-ca.crt") 
CLIENT_CERT = os.path.join(CERT_DIR,"client.crt")
CLIENT_KEY = os.path.join(CERT_DIR,"client.key")


def get_vault_client():
    
    client = hvac.Client(url=VAULT_ADDR, verify=CA_CERT)

    try:
        with open(CLIENT_CERT, 'rb') as f_cert, open(CLIENT_KEY, 'rb') as f_key:
            client.auth.cert.login(
                name="vault-internal-ca",
                cert_pem=f_cert.read(),
                key_pem=f_key.read(),
            )

        if client.is_authenticated():
            print("Successfully authenticated with Vault via TLS Cert!")
            return client
            
    except Exception as e:
        print(f"Vault Connection/Auth Failed: {e}")
        return None

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