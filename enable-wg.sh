sudo systemctl daemon-reload
sudo systemctl enable wg-quick@wg0.service
sudo systemctl start wg-quick@wg0
sudo bash -c 'echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf'
sudo bash -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'