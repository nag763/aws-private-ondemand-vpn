#!/usr/bin/env bash
set -euo pipefail

# Restrict permissions for all generated files
umask 077

CLIENT_PSK=$(wg genpsk)
CLIENT_KEY=$(wg genkey)
CLIENT_PUB=$(echo "$CLIENT_KEY" | wg pubkey)
SERVER_PUB=$(cat server.pub)

# Append Peer configuration to server wg0.conf
sudo bash -c "cat << EOF >> /etc/wireguard/wg0.conf

[Peer]
PublicKey = $CLIENT_PUB
PresharedKey = $CLIENT_PSK
AllowedIPs = 10.66.66.2/32,fd42:42:42::2/128
EOF"

# Discover instance public IP securely via IMDSv2, falling back to AWS checkip
PUBLIC_IP=""
IMDS_TOKEN=$(curl -s -S -f -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60" 2>/dev/null || true)
if [ -n "$IMDS_TOKEN" ]; then
  PUBLIC_IP=$(curl -s -S -f -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || true)
fi
if [ -z "$PUBLIC_IP" ]; then
  PUBLIC_IP=$(curl -4 -s -f https://checkip.amazonaws.com 2>/dev/null | tr -d '\n' || true)
fi

# Create client configuration file with umask 077
# DNS includes:
# 1) 10.66.66.1: Local VPN gateway DoT proxy (forwards to base.dns.mullvad.net over TLS on port 853)
# 2) 194.242.2.4, 2a07:e340::4: Direct Mullvad Base DNS (blocks ads, trackers, and malware)
cat << EOF > client.conf
[Interface]
Address = 10.66.66.2/32,fd42:42:42::2/128
PrivateKey = $CLIENT_KEY
DNS = 10.66.66.1, 194.242.2.4, 2a07:e340::4

[Peer]
PublicKey = $SERVER_PUB
PresharedKey = $CLIENT_PSK
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${PUBLIC_IP}:52180
PersistentKeepalive = 25
EOF

chmod 600 client.conf

# Render QR code for mobile WireGuard client
qrencode -t ansiutf8 < client.conf

echo "Scan the QR code above to connect to the WireGuard VPN."
echo "~~~~~~~~ Copy paste this configuration in your WireGuard client ~~~~~~~~"
cat client.conf
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

unset CLIENT_KEY CLIENT_PSK