#!/bin/bash

NODES=("master-A" "master-B" "master-C" "slave-A1" "slave-A2" "slave-B1" "slave-B2" "slave-C1" "slave-C2")
TEST_KEYS=(123 4658 3625 88834 466432 0 234 999899 8473 500000)

wait_for_cluster_recovery() {
    echo "Waiting for cluster to recover..."
    local attempts=0
    while [ $attempts -lt 30 ]; do
        cluster_state=$(docker exec master-A redis-cli cluster info 2>/dev/null | grep "cluster_state" | cut -d: -f2)
        if [ "$cluster_state" = "ok" ]; then
            echo "Cluster recovered"
            return 0
        fi
        sleep 2
        ((attempts++))
    done
    echo "Cluster failed to recover within timeout"
    return 1
}

check_cluster_status() {
    echo "=== Cluster Status ==="
    
    # Try different nodes as entry points
    for node in master-A master-B master-C; do
        if docker exec "$node" redis-cli ping >/dev/null 2>&1; then
            docker exec "$node" redis-cli cluster info 2>/dev/null | grep -E "(cluster_state|cluster_slots_assigned|cluster_known_nodes|cluster_size)"
            echo
            
            echo "=== Active Nodes ==="
            docker exec "$node" redis-cli cluster nodes 2>/dev/null | grep -v "fail" | awk '{print $2, $3}' | sort
            echo
            
            echo "=== Failed Nodes ==="
            docker exec "$node" redis-cli cluster nodes 2>/dev/null | grep "fail" | awk '{print $2, $3}' | sort
            echo
            return 0
        fi
    done
    
    echo "No accessible master nodes found"
    echo
}

check_key_values() {
    echo "=== Testing Key Retrieval ==="
    local missing_keys=0
    local cluster_down=0
    
    # Try different nodes as entry points
    local active_node=""
    for node in master-A master-B master-C; do
        if docker exec "$node" redis-cli ping >/dev/null 2>&1; then
            active_node="$node"
            break
        fi
    done
    
    if [ -z "$active_node" ]; then
        echo "No active nodes available for testing"
        return 1
    fi
    
    for key in "${TEST_KEYS[@]}"; do
        value=$(docker exec "$active_node" redis-cli -c get "$key" 2>/dev/null)
        if [ -z "$value" ] || [ "$value" = "(nil)" ]; then
            echo "MISSING: $key"
            ((missing_keys++))
        elif [[ "$value" == *"CLUSTERDOWN"* ]]; then
            echo "CLUSTER_DOWN: $key"
            ((cluster_down++))
        else
            echo "FOUND: $key = $value"
        fi
    done
    
    echo "Missing keys: $missing_keys/10"
    if [ $cluster_down -gt 0 ]; then
        echo "Cluster down responses: $cluster_down/10"
    fi
    echo
}

crash_node() {
    local node=$1
    echo "Crashing node: $node"
    docker stop "$node" >/dev/null 2>&1
    sleep 5
}

crash_group() {
    local group=$1
    echo "Crashing entire group: $group"
    case $group in
        "A")
            docker stop master-A slave-A1 slave-A2 >/dev/null 2>&1
            ;;
        "B")
            docker stop master-B slave-B1 slave-B2 >/dev/null 2>&1
            ;;
        "C")
            docker stop master-C slave-C1 slave-C2 >/dev/null 2>&1
            ;;
    esac
    sleep 5
}

# populate_test_data() {
#     echo "Populating test data..."
#     local active_node=""
#     for node in master-A master-B master-C; do
#         if docker exec "$node" redis-cli ping >/dev/null 2>&1; then
#             active_node="$node"
#             break
#         fi
#     done
    
#     if [ -z "$active_node" ]; then
#         echo "No active nodes available for data population"
#         return 1
#     fi
    
#     for key in "${TEST_KEYS[@]}"; do
#         value=$(echo "$key" | sed 's/key-//')
#         docker exec "$active_node" redis-cli -c set "$key" "$value" >/dev/null 2>&1
#     done
#     echo "Test data populated"
# }

restart_all() {
    echo "Restarting all nodes..."
    docker compose -p redis-cluster restart >/dev/null 2>&1
    sleep 15
    
    echo "Recreating cluster..."
    docker exec master-A redis-cli --cluster create \
        master-A:6379 master-B:6379 master-C:6379 \
        --cluster-yes >/dev/null 2>&1
    
    sleep 3
    
    MASTER_A_ID=$(docker exec master-A redis-cli cluster nodes | grep "master-A:6379@" | grep "master" | awk '{print $1}')
    MASTER_B_ID=$(docker exec master-B redis-cli cluster nodes | grep "master-B:6379@" | grep "master" | awk '{print $1}')
    MASTER_C_ID=$(docker exec master-C redis-cli cluster nodes | grep "master-C:6379@" | grep "master" | awk '{print $1}')
    
    docker exec slave-A1 redis-cli --cluster add-node slave-A1:6379 master-A:6379 --cluster-slave --cluster-master-id $MASTER_A_ID >/dev/null 2>&1
    sleep 1
    docker exec slave-A2 redis-cli --cluster add-node slave-A2:6379 master-A:6379 --cluster-slave --cluster-master-id $MASTER_A_ID >/dev/null 2>&1
    sleep 1
    docker exec slave-B1 redis-cli --cluster add-node slave-B1:6379 master-B:6379 --cluster-slave --cluster-master-id $MASTER_B_ID >/dev/null 2>&1
    sleep 1
    docker exec slave-B2 redis-cli --cluster add-node slave-B2:6379 master-B:6379 --cluster-slave --cluster-master-id $MASTER_B_ID >/dev/null 2>&1
    sleep 1
    docker exec slave-C1 redis-cli --cluster add-node slave-C1:6379 master-C:6379 --cluster-slave --cluster-master-id $MASTER_C_ID >/dev/null 2>&1
    sleep 1
    docker exec slave-C2 redis-cli --cluster add-node slave-C2:6379 master-C:6379 --cluster-slave --cluster-master-id $MASTER_C_ID >/dev/null 2>&1
    sleep 5
    
    wait_for_cluster_recovery
}

echo "Starting Redis Cluster Fault Tolerance Test"
echo "============================================"

echo "Generated test keys: ${TEST_KEYS[*]}"
echo

# populate_test_data
echo

echo "TEST 1: Crash Master Node A"
echo "============================"
crash_node "master-A"
wait_for_cluster_recovery
check_cluster_status
check_key_values

echo "TEST 2: Crash All But One Node From Each Group"
echo "=============================================="
restart_all
# populate_test_data
crash_node "slave-A1"
crash_node "slave-A2"
crash_node "slave-B1"
crash_node "slave-B2"
crash_node "slave-C1"
crash_node "slave-C2"
wait_for_cluster_recovery
check_cluster_status
check_key_values

echo "TEST 3: Crash Entire Group A"
echo "============================"
restart_all
generate_test_keys
# populate_test_data
crash_group "A"
sleep 10
check_cluster_status
check_key_values

echo "TEST SUMMARY"
echo "============"
echo "Test 1: Master failure - Expected: Slave promotion, minimal data loss"
echo "Test 2: Slave failures - Expected: Masters continue, full data availability"
echo "Test 3: Group failure - Expected: Partial cluster failure, some data loss"
echo
echo "Cluster fault tolerance testing complete"

restart_all
echo "All nodes restored"