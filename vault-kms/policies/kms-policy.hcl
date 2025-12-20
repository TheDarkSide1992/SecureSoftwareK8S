path "transit/rewrap/k8s-kek" {
  capabilities = ["update"]
}

path "transit/encrypt/k8s-kek" {
  capabilities = ["update"]
}

path "transit/decrypt/k8s-kek" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "transit/keys/k8s-kek" {
  capabilities = ["read"]
}