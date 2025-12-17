#!/bin/bash
set -euo pipefail

# Configurable variables
NAMESPACE="default"
SA_NAME="vault-auth"
JSON_FILE="consul/vault-k8s-auth.json"
TOKEN_TTL="720h"

# 1. Create namespace if it doesn't exist
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

# 2. Create Service Account
kubectl create sa "$SA_NAME" -n "$NAMESPACE" || echo "Service account already exists"

# 3. Create ClusterRoleBinding for Vault token review
kubectl get clusterrolebinding "vault-auth" >/dev/null 2>&1 || kubectl create clusterrolebinding vault-auth \
  --clusterrole=system:auth-delegator \
  --serviceaccount="$NAMESPACE":"$SA_NAME"

# 4. Read token reviewer JWT and CA cert
TOKEN_REVIEWER_JWT=$(kubectl get secret $(kubectl get sa "$SA_NAME" -n "$NAMESPACE" -o jsonpath='{.secrets[0].name}') -n "$NAMESPACE" -o jsonpath='{.data.token}' | base64 --decode)
K8S_CA_CERT=$(kubectl get secret $(kubectl get sa "$SA_NAME" -n "$NAMESPACE" -o jsonpath='{.secrets[0].name}') -n "$NAMESPACE" -o jsonpath='{.data.ca\.crt}' | base64 --decode)

# 5. Create Vault JSON file with proper PEM (multi-line)
cat > "$JSON_FILE" <<EOF
{
  "kubernetes_host": "https://kubernetes.default.svc.cluster.local",
  "token_reviewer_jwt": "$TOKEN_REVIEWER_JWT",
  "kubernetes_ca_cert": "$K8S_CA_CERT",
  "disable_iss_validation": true
}
EOF

echo "Vault auth JSON written to $JSON_FILE"
