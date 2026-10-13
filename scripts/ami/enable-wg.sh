#!/usr/bin/env bash
set -euo pipefail

# Enable IP forwarding in sysctl (both IPv4 and IPv6)
sudo bash -c 'cat << "EOF" > /etc/sysctl.d/99-wireguard.conf
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF'
sudo sysctl --system

# Configure systemd-resolved for Mullvad DoT (Ads + Trackers + Malware blocking)
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
sudo systemctl enable systemd-resolved || true
sudo systemctl enable wg-quick@wg0.service || true