#!/bin/bash

TEST_KEYS=(123 4658 3625 88834 466432 0 234 999899 8473 500000)

echo -e "\n==== Killing Master A ====\n"
docker kill master-A
sleep 2

echo -e "\n==== Cluster Info ====\n"
docker exec master-B redis-cli CLUSTER INFO 2>/dev/null | grep -E "(cluster_state|cluster_slots_assigned|cluster_known_nodes|cluster_size)"
sleep 1

echo -e "\n==== Cluster Nodes ====\n"
docker exec master-B redis-cli CLUSTER NODES 2>/dev/null | awk '{print $2, $3}' | sort
sleep 1

echo -e "\n==== Key Check After Master A Down ====\n"
for key in "${TEST_KEYS[@]}"; do
    echo -e "Key-${key}:"
    docker exec master-B redis-cli -c get "key-${key}" 2>/dev/null
done
sleep 2

echo -e "\n==== Crashing All But One Node per Group ====\n"
docker kill master-B
docker kill master-C
docker kill slave-A1
docker kill slave-B1
docker kill slave-C1
sleep 3

echo -e "\n==== Cluster Info After More Nodes Down ====\n"
docker exec master-B redis-cli CLUSTER INFO 2>/dev/null | grep -E "(cluster_state|cluster_slots_assigned|cluster_known_nodes|cluster_size)"
sleep 1

echo -e "\n==== Cluster Nodes After More Nodes Down ====\n"
docker exec master-B redis-cli CLUSTER NODES 2>/dev/null | awk '{print $2, $3}' | sort
sleep 1

echo -e "\n==== Key Check After Group Nodes Down ====\n"
for key in "${TEST_KEYS[@]}"; do
    echo -e "Key-${key}:"
    docker exec master-B redis-cli -c get "key-${key}" 2>/dev/null
done
sleep 2

echo -e "\n==== Crashing Entire Group C (Except 1) ====\n"
docker start master-A
docker start master-B
docker start slave-A1
docker start slave-B1
docker kill slave-C2
sleep 5

echo -e "\n==== Final Cluster Info ====\n"
docker exec master-B redis-cli CLUSTER INFO 2>/dev/null | grep -E "(cluster_state|cluster_slots_assigned|cluster_known_nodes|cluster_size)"
sleep 1

echo -e "\n==== Final Cluster Nodes ====\n"
docker exec master-B redis-cli CLUSTER NODES 2>/dev/null | awk '{print $2, $3}' | sort
sleep 1

echo -e "\n==== Final Key Check ====\n"
for key in "${TEST_KEYS[@]}"; do
    echo -e "Key-${key}:"
    docker exec master-B redis-cli -c get "key-${key}" 2>/dev/null
done
