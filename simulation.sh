#!/bin/bash


#########################################
# Author: Abrar Zahin
# Date: 16/02/2025
#
# This Script is about Network Namespace simulation
# Version : v1
#########################################

echo -e "Cleaning up any existing network configuration..."
ip netns del ns1 2>/dev/null
ip netns del ns2 2>/dev/null
ip netns del router-ns 2>/dev/null
ip link del br0 2>/dev/null
ip link del br1 2>/dev/null


echo "Creating Network Bridges and activate..."

sudo ip link add br0 type bridge
sudo ip link add br1 type bridge


sudo ip link set br0 up
sudo ip link set br1 up

echo "Creating Network Namespace..."

sudo ip netns add ns1
sudo ip netns add ns2
sudo ip netns add router-ns

echo "Namespaces: "

ip netns show

echo "Creating Virtual Interfaces and Connections..."

sudo ip link add veth-ns1 type veth peer name veth-ns-br0 
sudo ip link add veth-ns2 type veth peer name veth-ns-br1

sudo ip link add veth-r-br0 type veth peer name veth-r0
sudo ip link add veth-r-br1 type veth peer name veth-r1


sudo ip link set veth-ns1 netns ns1 up
sudo ip link set veth-ns2 netns ns2 up
sudo ip link set veth-r0 netns router-ns up
sudo ip link set veth-r1 netns router-ns up

sudo ip link set veth-ns-br0 master br0 up
sudo ip link set veth-ns-br1 master br1 up
sudo ip link set veth-r-br0 master br0 up
sudo ip link set veth-r-br1 master br1 up

echo "Configuring IP Addresses..." 
 

sudo ip addr add 10.11.0.1/24 dev br0
sudo ip addr add 10.12.0.1/24 dev br1

sudo ip netns exec ns1 ip addr add 10.11.0.2/24 dev veth-ns1
sudo ip netns exec ns2 ip addr add 10.12.0.2/24 dev veth-ns2

sudo ip netns exec router-ns ip addr add 10.11.0.3/24 dev veth-r0
sudo ip netns exec router-ns ip addr add 10.12.0.3/24 dev veth-r1

echo "Set Up Routing..."

echo "Establish default routes..."

sudo ip netns exec ns1 ip route add default via 10.11.0.1
sudo ip netns exec ns2 ip route add default via 10.12.0.1

echo "Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec router-ns sysctl -w net.ipv4.ip_forward=1

echo "Enabling firewall Rules..."
sudo iptables --append FORWARD --in-interface br0 --jump ACCEPT
sudo iptables --append FORWARD --out-interface br0 --jump ACCEPT

sudo iptables --append FORWARD --in-interface br1 --jump ACCEPT
sudo iptables --append FORWARD --out-interface br1 --jump ACCEPT

echo "Test connectivity from ns1 to ns2..."

ip netns exec ns1 ping 10.12.0.2 -c 3 

echo "Test connectivity from ns2 to ns1..."

ip netns exec ns1 ping 10.12.0.2 -c 3 
