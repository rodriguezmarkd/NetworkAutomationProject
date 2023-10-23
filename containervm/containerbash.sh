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

cp net-config-1.yaml /var/kvm/images/

cp net-config-2.yaml /var/kvm/images/

cp user-data.yaml /var/kvm/images/

cd /var/kvm/images/

wget https://static.alta3.com/projects/kvm/bionic-server-cloudimg-amd64.img

qemu-img resize bionic-server-cloudimg-amd64.img 8g

qemu-img info bionic-server-cloudimg-amd64.img

qemu-img convert -O qcow2 /var/kvm/images/bionic-server-cloudimg-amd64.img /var/kvm/images/beachhead.img

cp /var/kvm/images/beachhead.img /var/kvm/images/beachhead2.img

sudo mkdir /var/log/qemu

export KEY1="$(cat ~/.ssh/id_rsa.pub)"

MAC=$(printf "aa:a3:a3:%02x:%02x:%02x\n" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

MAC2=$(printf "aa:a3:a3:%02x:%02x:%02x\n" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

#echo $KEY1

cd /var/kvm/images

sudo apt-get install cloud-image-utils

echo 'instance-id: sdn-1-test
local-hostname:sdn-1-test' | sudo tee meta-data-1.yaml

echo 'instance-id: sdn-2-test
local-hostname:sdn-2-test' | sudo tee meta-data-2.yaml

cloud-localds cloud-init-1.iso user-data.yaml meta-data-1.yaml --network-config=net-config-1.yaml

cloud-localds cloud-init-2.iso user-data.yaml meta-data-2.yaml --network-config=net-config-2.yaml

sudo /sbin/iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE

sudo /sbin/iptables -A FORWARD -i ens3 -o pbridge -m state  --state RELATED,ESTABLISHED -j ACCEPT

sudo /sbin/iptables -A FORWARD -i pbridge -o ens3 -j ACCEPT

sudo /sbin/iptables -A FORWARD -i ens3 -o obridge -m state  --state RELATED,ESTABLISHED -j ACCEPT

sudo /sbin/iptables -A FORWARD -i obridge -o ens3 -j ACCEPT

sudo /sbin/iptables -A FORWARD -i ens3 -o br0 -m state  --state RELATED,ESTABLISHED -j ACCEPT

sudo /sbin/iptables -A FORWARD -i br0 -o ens3 -j ACCEPT

mkdir -p /var/log/qemu/

sudo /usr/bin/qemu-system-x86_64 \
   -enable-kvm \
   -drive file=/var/kvm/images/beachhead.img,if=virtio \
   -cdrom /var/kvm/images/cloud-init-1.iso \
   -display curses \
   -nographic \
   -smp cpus=1 \
   -m 1G \
   -net nic,netdev=tap1,macaddr=$MAC1 \
   -netdev bridge,id=tap1,br=pbridge\
   -d int \
   -D /var/log/qemu/qemu-1.log &

sudo /usr/bin/qemu-system-x86_64 \
   -enable-kvm \
   -drive file=/var/kvm/images/beachhead2.img,if=virtio \
   -cdrom /var/kvm/images/cloud-init-2.iso \
   -display curses \
   -nographic \
   -smp cpus=1 \
   -m 1G \
   -net nic,netdev=tap2,macaddr=$MAC2 \
   -netdev bridge,id=tap2,br=obridge\
   -d int \
   -D /var/log/qemu/qemu-2.log &
