service_prefix "ai-descriptor" {
  policy = "write"
}

service_prefix "create-service" {
  policy = "write"
}

service_prefix "gateway" {
  policy = "write"
}

service_prefix "review-handler" {
  policy = "write"
}

service_prefix "search-engine" {
  policy = "write"
}

service_prefix "web-frontend" {
  policy = "write"
}

node_prefix "" {
  policy = "read"
}

intention_prefix "" {
  policy = "read"
}