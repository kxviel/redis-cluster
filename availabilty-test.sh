#!/bin/bash

TEST_KEYS=(0 1 100 1000 10000 100000 500000 750000 900000 999999)

get_keys(){
    echo -e "\nGet Keys: "
    for key in "${TEST_KEYS[@]}"; do
        echo -e "Key-${key}: "
        docker exec master-B redis-cli -c get "key-${key}"
    done
    sleep 2
}

get_current_state(){
    echo -e "\nCluster Info: "
    docker exec master-B redis-cli CLUSTER INFO 2>/dev/null | grep -E "(cluster_state|cluster_slots_assigned|cluster_known_nodes|cluster_size)"
    echo -e "\nCluster Nodes: "
    docker exec master-B redis-cli CLUSTER NODES 2>/dev/null | awk '{print $2, $3}' | sort

    echo -e "\nWaiting for 5 secs... \n"
    sleep 5
}

timeout(){
    echo -e "\nWaiting for 20 secs... \n"
    sleep 20
}

echo -e "\nInitial State: "
get_current_state

echo -e "\nKilling Master A: \n"
docker kill master-A
timeout

get_current_state
get_keys