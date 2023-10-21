#!/bin/bash


echo 'br_netfilter' | sudo tee /etc/modules-load.d/br_nf.conf

sudo modprobe br_netfilter

echo 'net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0' | sudo tee /etc/sysctl.d/10-disable-firewall-on-bridge.conf

echo 'net.ipv4.ip_forward = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.all.forwarding = 1' | sudo tee /etc/sysctl.d/10-ip-forwarding.conf

sudo sysctl -p /etc/sysctl.d/10-disable-firewall-on-bridge.conf

sudo sysctl -p /etc/sysctl.d/10-ip-forwarding.conf

sudo sysctl -a | grep net.bridge.bridge

sudo mkdir -p /etc/qemu/

echo "allow br0" | sudo tee /etc/qemu/bridge.conf

sudo ip link add name br0 type bridge

sudo ip address add 172.16.0.1/24 dev br0

sudo ip link set br0 up

ip link show

brctl show 

sudo mkdir -p /var/kvm/images

sudo chown student:student /var/kvm/images

cd /var/kvm/images/

wget https://static.alta3.com/projects/kvm/bionic-server-cloudimg-amd64.img

qemu-img resize bionic-server-cloudimg-amd64.img 8g

qemu-img info bionic-server-cloudimg-amd64.img

qemu-img convert -O qcow2 /var/kvm/images/bionic-server-cloudimg-amd64.img /var/kvm/images/beachhead.img

sudo mkdir /var/log/qemu

MAC=$(printf "aa:a3:a3:%02x:%02x:%02x\n" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

sudo ip netns exec whost echo $KEY1

sudo ip netns exec whost cd /var/kvm/images

