wg genpsk > client.psk
wg genkey | tee client.key | wg pubkey > client.pub
sudo bash -c 'printf "\n[Peer]\nPublicKey = $(cat client.pub)\nPresharedKey = $(cat client.psk)\nAllowedIPs = 10.66.66.2/32,fd42:42:42::2/128"  >> /etc/wireguard/wg0.conf'
echo "[Interface]" >> client.conf
echo "Address = 10.66.66.2/32,fd42:42:42::2/128" >> client.conf
echo "PrivateKey = $(cat client.key)" >> client.conf
echo "[Peer]" >> client.conf
echo "AllowedIPs = 0.0.0.0/0, ::/0" >> client.conf
echo "Endpoint = $(curl -4 -s ifconfig.me):52180" >> client.conf
echo "PersistentKeepalive = 25" >> client.conf
echo "PublicKey = $(cat server.pub)" >> client.conf
echo "PresharedKey = $(cat client.psk)" >> client.conf
qrencode -t ansiutf8 < client.conf
echo "Scan the QR code above to connect to the WireGuard VPN."
echo "~~~~~~~~ Copy paste this configuration in your WireGuard client ~~~~~~~~"
cat client.conf
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"