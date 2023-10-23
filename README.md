# Network Automation Project
This is a repository for the capstone project by Ming Xia and Mark Rodriguez.

# Prerequisites
- sudo apt install dnsmasq -y
- sudo apt install bridge-utils

## Description of Main Files
_network_topology.yml_ - This file is the data structure for the overall network topology for the project.
This document is used as the structure for the network. It contains the below categories:
- Subnets
- Routers
- Hosts

_main.py_ - This file is the primary script for generating the virtual network. It pulls the structure from _network_toplogy.yml_. It contains the following classes:
- main() - Calls build_network function
- populate_dict() - Creates topology dictionary using network_topology.yml
- build_network(topology) - Catalyst for rest of script, calls all other functions in order
- add_routes(topology) - Using network_topology.yml file, creates routes for virtual devices
- configure_nat() - Configures NAT functionality so virtual hosts can access Internet resources

_networktests.yml_ - This is an ansible script that performs end-to-end testing for the virtual network. Information is then output into networktestsresults.log in JSON format.
- "IP Configuration Readout from Each Host" - Pulls the command 'ip -c link' from each host to verify configuration information.
- "Pinging Outward" - This task performs a simple ping from each host to 8.8.8.8.
- "Pinging from hosts to core router" - This task tests LAN functionality within the virtual network.
- "Show Results" - This task outputs the results to the screen
- "Outputting results to file..." - This task creates the log file

_teardown.py_ - This script deactivates the virtual network