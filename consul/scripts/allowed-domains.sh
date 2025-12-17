#!/bin/sh
# NAME is set to either the value from `global.name` from the consul value file
export NAME=consul
# kubernetes namespace that Consul is running in
export NAMESPACE=consul
# Name for the consul datacenter from the consul value file
export DATACENTER=dc1
#list of allowed domains
echo allowed_domains=\"$DATACENTER.consul, $NAME-server, $NAME-server.$NAMESPACE, $NAME-server.$NAMESPACE.svc\"