#!/usr/bin/env bash

# Script that will update the local /etc/hosts file with the various ingress gateway IP addresses
# get domain from argument
DOMAIN=$1
if [ -z "$DOMAIN" ]; then
  DOMAIN="bigbang.dev"
fi
echo "Setting up /etc/hosts for domain: $DOMAIN"

# enable common error handling options
set -o errexit
set -o nounset
set -o pipefail

admin_ingressgateway_ip=10.0.255.1
tenant_ingressgateway_ip=10.0.255.2
keycloak_ingressgateway_ip=10.0.255.3

grep -qxF "${admin_ingressgateway_ip} kiali.$DOMAIN grafana.$DOMAIN neuvector.$DOMAIN tracing.$DOMAIN " /etc/hosts || echo "${admin_ingressgateway_ip} kiali.$DOMAIN grafana.$DOMAIN neuvector.$DOMAIN tracing.$DOMAIN" | tee -a /etc/hosts
grep -qxF "${keycloak_ingressgateway_ip} keycloak.$DOMAIN" /etc/hosts || echo "${keycloak_ingressgateway_ip} keycloak.$DOMAIN" | tee -a /etc/hosts
grep -qxF "${tenant_ingressgateway_ip} podinfo.$DOMAIN" /etc/hosts || echo "${tenant_ingressgateway_ip} podinfo.$DOMAIN" | tee -a /etc/hosts
