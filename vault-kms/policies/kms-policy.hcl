path "transit/rewrap/k8s-kek" {
  capabilities = ["update"]
}

path "transit/encrypt/k8s-kek" {
  capabilities = ["update"]
}

path "transit/decrypt/k8s-kek" {
  capabilities = ["update"]
}

path "auth/cert/login" {
  capabilities = ["create", "read"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "transit/keys/k8s-kek" {
  capabilities = ["read"]
}