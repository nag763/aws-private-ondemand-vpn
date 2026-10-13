wg genkey | tee server.key | wg pubkey > server.pub
sudo bash -c 'printf "[Interface]\n" >> /etc/wireguard/wg0.conf'
sudo bash -c 'printf "Address = 10.66.66.1/24,fd42:42:42::1/64\n" >> /etc/wireguard/wg0.conf'
sudo bash -c 'printf "ListenPort = 52180\n" >> /etc/wireguard/wg0.conf'
sudo bash -c 'printf "PrivateKey = $(cat server.key)\n" >> /etc/wireguard/wg0.conf'
sudo bash -c 'printf "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o enX0 -j MASQUERADE\n" >> /etc/wireguard/wg0.conf'
sudo bash -c 'printf "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o enX0 -j MASQUERADE\n" >> /etc/wireguard/wg0.conf'
rm server.key 