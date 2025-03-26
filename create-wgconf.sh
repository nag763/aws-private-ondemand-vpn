wg genkey | tee server.key | wg pubkey > server.pub
wg genkey | tee client.key | wg pubkey > client.pub
wg genpsk > client.psk
sudo bash -c 'printf "[Interface]\nAddress = 10.66.66.1/24,fd42:42:42::1/64\nListenPort = 52180\nPrivateKey = $(cat server.key)\nPostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o enX0 -j MASQUERADE\nPostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o enX0 -j MASQUERADE\n[Peer]\nPublicKey = $(cat client.pub)\nPresharedKey = $(cat client.psk)\nAllowedIPs = 10.66.66.2/32,fd42:42:42::2/128" >> /etc/wireguard/wg0.conf'
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
rm client.psk *.key *.pub client.conf