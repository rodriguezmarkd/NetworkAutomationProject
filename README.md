# Network Automation Project
This is a repository for the capstone project by Ming Xia and Mark Rodriguez.

## Description of Main Files
_network_topology.yml_ - This file is the data structure for the overall network topology for the project.
This document is used as the structure for the network. It contains the below categories:
- Subnets
- Routers
- Hosts

_main.py_ - This file is the primary script for generating the virtual network. It pulls the structure from _network_toplogy.yml_. It contains the following classes:
- main()
- deploy_network()