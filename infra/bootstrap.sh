#!/usr/bin/env bash

set -o errexit -o pipefail -o noclobber -o nounset

sudo dnf update -y
sudo dnf install -y wireguard-tools
sudo dnf clean all

sudo mv "$wg_conf" /etc/sysctl.d/
sudo mv "$www0_conf" /etc/wireguard/
sudo mv "$www_bin" /usr/local/bin/
sudo mv "$www_service" /etc/systemd/system/

sudo systemctl enable wg-quick@wg0
sudo systemctl enable www@8080
