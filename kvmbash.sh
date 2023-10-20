#!/bin/bash



sudo ip netns exec whost ip address show

sudo ip netns exec whost sudo apt update
sudo ip netns exec whost sudo apt install -y bridge-utils
sudo ip netns exec whost sudo apt install -y qemu-kvm
sudo ip netns exec whost sudo apt install -y cloud-utils
sudo ip netns exec whost kvm-ok

sudo ip netns exec whost echo 'br_netfilter' | sudo tee /etc/modules-load.d/br_nf.conf

sudo ip netns exec whost sudo modprobe br_netfilter
sudo ip netns exec whost echo 'net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0' | sudo tee /etc/sysctl.d/10-disable-firewall-on-bridge.conf

sudo ip netns exec whost echo 'net.ipv4.ip_forward = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.all.forwarding = 1' | sudo tee /etc/sysctl.d/10-ip-forwarding.conf

sudo ip netns exec whost sudo sysctl -p /etc/sysctl.d/10-disable-firewall-on-bridge.conf

sudo ip netns exec whost sudo sysctl -p /etc/sysctl.d/10-ip-forwarding.conf

sudo ip netns exec whost sudo sysctl -a | grep net.bridge.bridge

sudo ip netns exec whost sudo mkdir -p /etc/qemu/

sudo ip netns exec whost echo "allow br0" | sudo tee /etc/qemu/bridge.conf

sudo ip netns exec whost sudo ip link add name br0 type bridge

sudo ip netns exec whost sudo ip address add 172.16.0.1/24 dev br0

sudo ip netns exec whost sudo ip link set br0 up

sudo ip netns exec whost ip link show

sudo ip netns exec whost brctl show 

sudo ip netns exec whost sudo mkdir -p /var/kvm/images

sudo ip netns exec whost sudo chown student:student /var/kvm/images

sudo ip netns exec whost cd /var/kvm/images/

sudo ip netns exec whost wget https://static.alta3.com/projects/kvm/bionic-server-cloudimg-amd64.img

sudo ip netns exec whost qemu-img info bionic-server-cloudimg-amd64.img

sudo ip netns exec whost qemu-img resize bionic-server-cloudimg-amd64.img 8g

sudo ip netns exec whost qemu-img info bionic-server-cloudimg-amd64.img

sudo ip netns exec whost qemu-img convert -O qcow2 /var/kvm/images/bionic-server-cloudimg-amd64.img /var/kvm/images/beachhead.img

sudo ip netns exec whost MAC=$(printf "aa:a3:a3:%02x:%02x:%02x\n" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

sudo ip netns exec whost echo $KEY1

sudo ip netns exec whost cd /var/kvm/images

