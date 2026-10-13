#!/usr/bin/env bash
set -euo pipefail

# Securely wipe client config and temporary key files
rm -f client.psk client.key client.pub server.pub client.conf *.key *.pub

# Start or restart WireGuard with the newly added peer
sudo systemctl daemon-reload
sudo systemctl restart wg-quick@wg0

# Note: We intentionally avoid `sudo cat /etc/wireguard/wg0.conf` to prevent
# leaking the server private key and client pre-shared key into Terraform logs.

# Lock the ec2-user login shell
sudo usermod -s /sbin/nologin ec2-user || true

# Asynchronously mask and stop SSH sockets and services to allow provisioner to exit cleanly
( sleep 2 && sudo systemctl mask --now sshd.socket sshd.service ssh.socket ssh.service ) >/dev/null 2>&1 &