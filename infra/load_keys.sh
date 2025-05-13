#!/usr/bin/env bash

wg genkey | tee server_private.key | wg pubkey > server_public.key
wg genkey | tee client_private.key | wg pubkey > client_public.key

trap "rm *.key" EXIT

terraform apply \
  -var="server_public_key=$(cat server_public.key)" \
  -var="server_private_key=$(cat server_private.key)" \
  -var="client_public_key=$(cat client_public.key)" \
  -var="client_private_key=$(cat client_private.key)"
