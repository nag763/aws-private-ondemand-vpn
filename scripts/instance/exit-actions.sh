rm client.psk *.key *.pub client.conf 
sudo systemctl restart wg-quick@wg0
sudo cat /etc/wireguard/wg0.conf
sudo usermod -s /sbin/nologin ec2-user
sudo systemctl disable sshd
sudo systemctl stop sshd