#!/bin/bash
set -euox pipefail

# Install
python3 -m pip install --user j2cli
ssh-keyscan -t rsa alpha   >> ~/.ssh/known_hosts
ssh-keygen -H
rm ~/.ssh/known_hosts.old

ssh alpha   sudo apt install -y wireguard 
mkdir -p ~/wg
pushd ~/wg

### Configuration Generation
export WG_ALPHA_PUB=$(cat keys/alpha.pub)
export WG_ALPHA_KEY=$(cat keys/alpha.key)
export WG_BRAVO_PUB=$(cat keys/bravo.pub)
export WG_BRAVO_KEY=$(cat keys/bravo.key)
export WG_CHARLIE_PUB=$(cat keys/charlie.pub)
export WG_CHARLIE_KEY=$(cat keys/charlie.key)
export WG_BCHD_PUB=$(cat keys/bchd.pub)
export WG_BCHD_KEY=$(cat keys/bchd.key)

mkdir -p j2
wget -q https://labs.alta3.com/courses/sd-wan/scripts/wg-basic/alpha.conf.j2 -O j2/alpha.conf.j2
mkdir -p conf
j2 j2/alpha.conf.j2   > conf/alpha.conf
cat conf/alpha.conf   | ssh alpha   sudo tee /etc/wireguard/wg0.conf
popd

### Starup
ssh alpha   sudo ip link add dev wg0 type wireguard
ssh alpha   sudo wg setconf wg0 /etc/wireguard/wg0.conf
ssh alpha   sudo ip -4 address add 10.64.0.1/32 dev wg0
ssh alpha   sudo ip link set mtu 1500 up dev wg0 
ssh alpha   sudo ip -4 route add 10.65.0.0/16 dev wg0
ssh alpha   sudo ip -4 route add 10.66.0.0/16 dev wg0
ssh alpha   sudo ip -4 route add 10.67.0.1/32 dev wg0
