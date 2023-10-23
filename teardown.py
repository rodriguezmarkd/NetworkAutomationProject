#!/usr/bin/env python3

import yaml
import subprocess

def populate_dict():
    topology = {}
    with open('network_topology.yml', 'r') as reader:
        topology = yaml.load(reader, Loader=yaml.FullLoader)
    return topology
    

def strike_network(topology):
    print("Tearing down namespaces...")
    for routers in topology['routers']:
        #print(type(routers))
        print(f"Deleting {routers['name']} namespace...")
        subprocess.call(['sudo','ip','netns','delete',routers['name']])
    for hosts in topology['hosts']:
        print(f"Deleting {hosts['name']} namespace and associated links...")
        subprocess.call(['sudo','ip','netns','delete',hosts['name']])
        #subprocess.call(['sudo','ip','link','del',hosts['name'] + '2' + hosts['name'] + 'brdg','type','veth','peer','name',hosts['name'] + 'brdg' + '2' + hosts['name']])
        #subprocess.call(['sudo','ip','link','del',hosts['name'] + 'brdg' + '2' + hosts['name']])
    for bridges in topology['subnets']:
        if bridges['bridge'] == True:
            print(f"Deleting {bridges['bridge_name']}brdg...")
            subprocess.call(['sudo','ip','link','delete',bridges['bridge_name']])
def main():
    network_topology = populate_dict()
    strike_network(network_topology)
    #print(network_topology)
    subprocess.call(['sudo','ip','netns'])

if __name__ == '__main__':
    main()