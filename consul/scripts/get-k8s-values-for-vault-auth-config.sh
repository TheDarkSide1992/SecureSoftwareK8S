#!/bin/bash
set -euo pipefail

# Konfigurerbare variabler
NAMESPACE="default"
SA_NAME="vault-auth"
SECRET_NAME="vault-auth-token"
JSON_FILE="./consul/vault-k8s-auth.json"

# 1. Opret namespace hvis det ikke findes
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

# 2. Opret Service Account
kubectl get sa "$SA_NAME" -n "$NAMESPACE" >/dev/null 2>&1 || kubectl create sa "$SA_NAME" -n "$NAMESPACE"

# 3. Manuel oprettelse af Secret (Nødvendigt i nyere K8s/Minikube)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/service-account.name: "$SA_NAME"
type: kubernetes.io/service-account-token
EOF

# 4. Opret ClusterRoleBinding
kubectl get clusterrolebinding "vault-auth" >/dev/null 2>&1 || kubectl create clusterrolebinding vault-auth \
  --clusterrole=system:auth-delegator \
  --serviceaccount="$NAMESPACE":"$SA_NAME"

# Vent et øjeblik på at K8s genererer token i den nye secret
sleep 2

# 5. Udtræk token og CA certifikat
# Vi bruger --raw for at undgå whitespace problemer og dekoder fra base64
TOKEN_REVIEWER_JWT=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.token}' | base64 --decode)
K8S_CA_CERT=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.ca\.crt}' | base64 --decode)

# 6. Generer Vault JSON fil
# Bemærk: Vi bruger jq hvis muligt for at sikre korrekt JSON-formatering af multiline certifikater
if command -v jq >/dev/null 2>&1; then
  jq -n \
    --arg host "https://kubernetes.default.svc.cluster.local" \
    --arg jwt "$TOKEN_REVIEWER_JWT" \
    --arg ca "$K8S_CA_CERT" \
    '{kubernetes_host: $host, token_reviewer_jwt: $jwt, kubernetes_ca_cert: $ca, disable_iss_validation: true}' \
    > "$JSON_FILE"
else
  # Fallback til cat hvis jq ikke er installeret
  cat > "$JSON_FILE" <<EOF
{
  "kubernetes_host": "https://kubernetes.default.svc.cluster.local",
  "token_reviewer_jwt": "$TOKEN_REVIEWER_JWT",
  "kubernetes_ca_cert": "$(echo "$K8S_CA_CERT" | sed 's/$/\\n/' | tr -d '\n')",
  "disable_iss_validation": true
}
EOF
fi

echo "Succes: Vault auth JSON er skrevet til $JSON_FILE"