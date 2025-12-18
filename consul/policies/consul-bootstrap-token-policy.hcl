path "secret/data/consul-bootstrap-token" {
    capabilities = ["create","update","read","list"]
  }
  path "secret/data/consul-bootstrap-token/*" {
    capabilities = ["create","update","read","list"]
  }

  path "secret/metadata/consul-bootstrap-token" {
    capabilities = ["read","list"]
  }
  path "secret/metadata/consul-bootstrap-token/*" {
    capabilities = ["read","list"]
  }

  path "sys/internal/ui/mounts/secret" {
    capabilities = ["read","list"]
  }

path "sys/internal/*" {
  capabilities = ["read","list"]
}