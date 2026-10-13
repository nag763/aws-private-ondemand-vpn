#!/usr/bin/env bash
set -euo pipefail

# Enforce secure umask so private keys and configs are only accessible by owner
umask 077

# Ensure /etc/wireguard directory exists with restricted permissions
sudo mkdir -p /etc/wireguard
sudo chmod 700 /etc/wireguard

# Detect default network interface dynamically (supports Xen enX0, Nitro ens5, eth0, etc.)
DEFAULT_IF=$(ip route show default 2>/dev/null | awk '{print $5}' | head -n1)
if [ -z "$DEFAULT_IF" ]; then
  DEFAULT_IF="eth0"
fi

# Generate fresh server keypair on this specific instance
SERVER_KEY=$(wg genkey)
SERVER_PUB=$(echo "$SERVER_KEY" | wg pubkey)

# Save server public key for client generation
echo "$SERVER_PUB" > server.pub
chmod 600 server.pub

# Configure systemd-resolved for Mullvad DNS-over-TLS (Ads + Trackers + Malware blocking)
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo bash -c 'cat << "EOF" > /etc/systemd/resolved.conf.d/00-mullvad-dot.conf
[Resolve]
DNS=194.242.2.4#base.dns.mullvad.net 2a07:e340::4#base.dns.mullvad.net
DNSOverTLS=yes
DNSStubListener=yes
DNSStubListenerExtra=10.66.66.1
Cache=yes
EOF'

sudo systemctl daemon-reload
sudo systemctl enable --now systemd-resolved || true
sudo systemctl restart systemd-resolved || true

# Write server WireGuard configuration with strict file permissions (0600)
sudo bash -c "cat << EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.66.66.1/24,fd42:42:42::1/64
ListenPort = 52180
PrivateKey = $SERVER_KEY
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $DEFAULT_IF -j MASQUERADE; ip6tables -A FORWARD -i %i -j ACCEPT 2>/dev/null || true; ip6tables -t nat -A POSTROUTING -o $DEFAULT_IF -j MASQUERADE 2>/dev/null || true
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $DEFAULT_IF -j MASQUERADE; ip6tables -D FORWARD -i %i -j ACCEPT 2>/dev/null || true; ip6tables -t nat -D POSTROUTING -o $DEFAULT_IF -j MASQUERADE 2>/dev/null || true
EOF"

sudo chmod 600 /etc/wireguard/wg0.conf
unset SERVER_KEY