#!/usr/bin/env python3

import yaml
import subprocess

def populate_dict():
    topology = {}
    with open('network_topology.yml', 'r') as reader:
        topology = yaml.load(reader, Loader=yaml.FullLoader)
    return topology
    
def deploy_bridges(topology):
    for bridges in topology['subnets']:
        # Creating bridges using subnets YAML. If Bridge is not null, creates bridge. Also sets bridge to up
        #    sudo ip link add name {name} type bridge
        #    sudo ip link set dev {bridge_name} up
        if bridges['bridge'] == True:
            print(f"Creating {bridges['bridge_name']} namespace...")
            subprocess.call(['sudo','ip','link','add','name',bridges['bridge_name'],'type','bridge'])
            print(f"Setting {bridges['name']}bridge to an up state...")
            subprocess.call(['sudo','ip','link','set','dev',bridges['bridge_name'],'up'])
    subprocess.call(['sudo','sysctl','net.bridge.bridge-nf-call-iptables=0'])
    subprocess.call(['echo','\'net.ipv4.ip_forward','=','1\n','net.ipv6.conf.default.forwarding','=','1\n','net.ipv6.conf.all.forwarding','=','1\'','|','sudo','tee','/etc/sysctl.d/10-ip-forwarding.conf'])

def deploy_routers(topology):
    for routers in topology['routers']:
        print(f"***Creating {routers['name']} namespace...***")
        # Creates routers namespace
        #    sudo ip netns add {routers_name}
        subprocess.call(['sudo','ip','netns','add',routers['name']])
        if routers['ds_bridge'] != None:
            # Creates links for router2bridge, sets router2bridge up
            #    sudo ip link add {routers_name}2{routers_dsbridge} type veth peer name {routers_dsbridge}2{routers_name}
            #    sudo ip link set {routers_name}2{routers_dsbridge} netns {routers_name}
            #    sudo ip link set dev {routers_dsbridge}2{routers_name} master {routers_dsbridge}
            #    sudo ip link set dev {routers_dsbridge}2{routers_name} up
            subprocess.call(['sudo','ip','link','add',routers['name'] + '2' + routers['ds_bridge'],'type','veth','peer','name',routers['ds_bridge'] + '2' + routers['name']])
            subprocess.call(['sudo','ip','link','set',routers['name'] + '2' + routers['ds_bridge'],'netns',routers['name']])
            subprocess.call(['sudo','ip','link','set','dev',routers['ds_bridge'] + '2' + routers['name'],'master',routers['ds_bridge']])
            subprocess.call(['sudo','ip','link','set','dev',routers['ds_bridge'] + '2' + routers['name'],'up'])
        elif routers['ds_bridge'] == None:
            for interfaces in routers['interfaces']:
                if interfaces['peer'] != None:
                    subprocess.call(['sudo','ip','link','add',interfaces['name'],'type','veth','peer','name',interfaces['peer'] + '2' + 'core'])
                    subprocess.call(['sudo','ip','link','set',interfaces['name'],'netns',routers['name']])
                    subprocess.call(['sudo','ip','link','set',interfaces['peer'] + '2' + 'core','netns',interfaces['peer']])
        subprocess.call(['sudo','ip','netns','exec',routers['name'],'sysctl','-p','/etc/sysctl.d/10-ip-forwarding.conf']) 

def deploy_hosts(topology):
    for hosts in topology['hosts']:
        print(f"Creating {hosts['name']} namespace...")

        subprocess.call(['sudo','ip','netns','add',hosts['name']])
        subprocess.call(['sudo','ip','link','add',hosts['name'] + '2' + hosts['bridge'],'type','veth','peer','name',hosts['bridge'] + '2' + hosts['name']])
        subprocess.call(['sudo','ip','link','set',hosts['name'] + '2' + hosts['bridge'],'netns', hosts['name']])
        subprocess.call(['sudo','ip','link','set','dev',hosts['bridge'] + '2' + hosts['name'],'master', hosts['bridge']])
        subprocess.call(['sudo','ip','link','set','dev',hosts['bridge'] + '2' + hosts['name'],'up'])

        print(f"Configuring {hosts['name']} with an IP of {hosts['ip']}")
        # sudo ip netns exec {hosts_name} ip addr add {hosts_ip}/24 dev {hosts_ifname}
        # sudo ip netns exec {hosts_name} ip link set dev {hosts_ifname} up
        # sudo ip netns exec {hosts_name} ip link set dev lo up
        subprocess.call(['sudo','ip','netns','exec',hosts['name'],'ip','addr','add',hosts['ip'],'dev',hosts['name'] + '2' + hosts['bridge']])
        subprocess.call(['sudo','ip','netns','exec',hosts['name'],'ip','link','set','dev',hosts['name'] + '2' + hosts['bridge'],'up'])
        subprocess.call(['sudo','ip','netns','exec',hosts['name'],'ip','link','set','dev','lo','up'])

def deploy_router_ips(topology):
    for routers in topology['routers']:
        for interfaces in routers['interfaces']:
            #print(f"Adding {interfaces}")
            subprocess.call(['sudo','ip','netns','exec',routers['name'],'ip','addr','add',interfaces['ip'],'dev',interfaces['name']])
            subprocess.call(['sudo','ip','netns','exec',routers['name'],'ip','link','set','dev',interfaces['name'],'up'])
            subprocess.call(['sudo','ip','netns','exec',routers['name'],'ip','link','set','dev','lo','up'])   

def add_routes(topology):
    for network in topology['subnets']:
        subprocess.call(['sudo','ip','netns','exec','core','ip','route','add',network['network'],'via',network['route']])
    for hosts in topology['hosts']:
        subprocess.call(['sudo','ip','netns','exec',hosts['name'],'ip','route','add','default','via',hosts['default']])
    for routers in topology['routers']:
        subprocess.call(['sudo','ip','netns','exec',routers['name'],'ip','route','add','default','via',routers['nexthop']])

def configure_nat():

    subprocess.call(['sudo','ip','link','add','core2nat','type','veth','peer','name','nat2core'])
    subprocess.call(['sudo','ip','link','set','core2nat','netns','core'])

    subprocess.call(['sudo','ip','netns','exec','core','ip','addr','add','10.1.5.17/30','dev','core2nat'])
    subprocess.call(['sudo','ip','netns','exec','core','ip','link','set','dev','core2nat','up'])

    subprocess.call(['sudo','ip','addr','add','10.1.5.18/30','dev','nat2core'])

    subprocess.call(['sudo','ip','addr','add','192.168.90.3/24','dev','pbridge2prouter'])
    subprocess.call(['sudo','ip','addr','add','192.168.90.4/24','dev','pbridge'])

    subprocess.call(['sudo','iptables','-t','nat','-F'])
    subprocess.call(['sudo','iptables','-t','nat','-A','POSTROUTING','-s','10.1.0.0/16','-o','ens3','-j','MASQUERADE']) 
    subprocess.call(['sudo','iptables','-t','filter','-A','FORWARD','-i','ens3','-o','nat2core','-j','ACCEPT'])  
    subprocess.call(['sudo','iptables','-t','filter','-A','FORWARD','-o','ens3','-i','nat2core','-j','ACCEPT'])
    subprocess.call(['sudo','ip','route','add','10.1.0.0/16','via','10.1.5.17']) 

    subprocess.call(['sudo','iptables','-t','filter','-A','FORWARD','-i','ens3','-o','nat2crout','-j','ACCEPT'])  
    subprocess.call(['sudo','iptables','-t','filter','-A','FORWARD','-o','ens3','-i','nat2crout','-j','ACCEPT'])
    subprocess.call(['sudo','ip','netns','exec','core','ip','route','add','default','via','10.1.5.18']) 


def build_network(topology):
    print("Creating namespaces...")
    deploy_bridges(topology)
    
    print("Creating Routers")
    deploy_routers(topology)

    print("Deploying hosts...")
    deploy_hosts(topology)

    print("Adding Router IP Addresses...")
    deploy_router_ips(topology)

    print("Adding routes to devices...")
    add_routes(topology)

    print("Configuring NAT and DHCP...")
    configure_nat()

def main():
    network_topology = populate_dict()

    build_network(network_topology)

    print("Showing Created Namespaces...")
    subprocess.call(['sudo','ip','netns'])

    print("Showing up bridges")
    subprocess.call(['sudo','brctl','show'])

if __name__ == '__main__':
    main()

