echo '{
  "server_public_key": "{{ op://couetil.com/wireguard/server/public_key }}",
  "server_private_key": "{{ op://couetil.com/wireguard/server/private_key }}",
  "client_public_key": "{{ op://couetil.com/wireguard/client/public_key }}",
  "client_private_key": "{{ op://couetil.com/wireguard/client/private_key }}"
}' | op inject
