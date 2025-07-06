#!/bin/bash

TEST_KEYS=(0 1 100 1000 10000 100000 500000 750000 900000 999999)

# Function to find a working node
find_working_node() {
    local nodes=("master-A" "master-B" "master-C" "slave-A1" "slave-A2" "slave-B1" "slave-B2" "slave-C1" "slave-C2")
    for node in "${nodes[@]}"; do
        if docker exec $node redis-cli ping 2>/dev/null | grep -q PONG; then
            echo $node
            return 0
        fi
    done
    return 1
}

# Function to check cluster state from any working node
check_cluster_state() {
    local working_node=$(find_working_node)
    if [ $? -eq 0 ]; then
        echo "Using node: $working_node"
        docker exec $working_node redis-cli CLUSTER INFO 2>/dev/null | grep -E "(cluster_state|cluster_slots_assigned|cluster_known_nodes|cluster_size)"
    else
        echo "No working nodes found!"
    fi
}

# Function to show cluster nodes from any working node
show_cluster_nodes() {
    local working_node=$(find_working_node)
    if [ $? -eq 0 ]; then
        docker exec $working_node redis-cli CLUSTER NODES 2>/dev/null | awk '{print $2, $3}' | sort
    else
        echo "No working nodes found!"
    fi
}

# Function to test keys from any working node
test_keys() {
    local working_node=$(find_working_node)
    if [ $? -eq 0 ]; then
        for key in "${TEST_KEYS[@]}"; do
            echo -e "Key-${key}:"
            docker exec $working_node redis-cli -c get "key-${key}" 2>/dev/null || echo "  Key not accessible"
        done
    else
        echo "No working nodes found!"
    fi
}

echo -e "\n==== Initial Cluster State ====\n"
check_cluster_state
sleep 1

echo -e "\n==== Killing Master A ====\n"
docker kill master-A
echo -e "\n 10 Seconds wait for failover to complete\n"
sleep 10

echo -e "\n==== Cluster Info After Master A Down ====\n"
check_cluster_state
sleep 1

echo -e "\n==== Cluster Nodes After Master A Down ====\n"
show_cluster_nodes
sleep 1

echo -e "\n==== Key Check After Master A Down ====\n"
test_keys
sleep 2

echo -e "\n==== Crashing Multiple Nodes (Keep 1 per group) ====\n"
docker kill master-B
docker kill master-C
docker kill slave-A1
docker kill slave-B1
docker kill slave-C1
echo -e "\n 10 Seconds wait for failover to complete\n"
sleep 10

echo -e "\n==== Cluster Info After More Nodes Down ====\n"
check_cluster_state
sleep 1

echo -e "\n==== Cluster Nodes After More Nodes Down ====\n"
show_cluster_nodes
sleep 1

echo -e "\n==== Key Check After Group Nodes Down ====\n"
test_keys
sleep 2

echo -e "\n==== Restarting Some Nodes ====\n"
docker start master-A
docker start master-B
docker start slave-A1
docker start slave-B1
docker kill slave-C2
echo -e "\n 10 Seconds wait for cluster to stabilize\n"
sleep 10

echo -e "\n==== Final Cluster Info ====\n"
check_cluster_state
sleep 1

echo -e "\n==== Final Cluster Nodes ====\n"
show_cluster_nodes
sleep 1

echo -e "\n==== Final Key Check ====\n"
test_keys

echo -e "\n==== Test Complete ====\n"