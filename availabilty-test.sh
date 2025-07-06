#!/bin/bash

TEST_KEYS=(0 1 100 1000 10000 100000 500000 750000 900000 999999)

get_current_state(){
    echo -e "\nCluster Info: "
    docker exec master-B redis-cli CLUSTER INFO 2>/dev/null | grep -E "(cluster_state|cluster_slots_assigned|cluster_known_nodes|cluster_size)"
    echo -e "\nCluster Nodes: "
    docker exec master-B redis-cli CLUSTER NODES 2>/dev/null | awk '{print $2, $3}' | sort

    echo -e "\nWaiting for 5 secs... \n"
    sleep 5
}

timeout(){
    echo -e "\nWaiting for 15 secs... \n"
    sleep 15
}

echo -e "\nInitial State: "
get_current_state

echo -e "\nKilling Master A: \n"
docker kill master-A
timeout
get_current_state


echo -e "\nGet Keys: "
for key in "${TEST_KEYS[@]}"; do
    echo -e "Key-${key}: $(docker exec master-B redis-cli -c get "key-${key}")"
done
sleep 2

echo -e "\nCrashing All But One Node per Group: "
docker kill master-B
docker kill master-C
docker kill slave-A1
docker kill slave-B1
docker kill slave-C1
timeout
get_current_state


# echo -e "\n==== Cluster Info After More Nodes Down ====\n"
# docker exec master-B redis-cli CLUSTER INFO 2>/dev/null | grep -E "(cluster_state|cluster_slots_assigned|cluster_known_nodes|cluster_size)"
# sleep 1

# echo -e "\n==== Cluster Nodes After More Nodes Down ====\n"
# docker exec master-B redis-cli CLUSTER NODES 2>/dev/null | awk '{print $2, $3}' | sort
# sleep 1

# echo -e "\n==== Key Check After Group Nodes Down ====\n"
# for key in "${TEST_KEYS[@]}"; do
#     echo -e "Key-${key}:"
#     docker exec master-B redis-cli -c get "key-${key}" 2>/dev/null
# done
# sleep 2

# echo -e "\n==== Crashing Entire Group C (Except 1) ====\n"
# docker start master-A
# docker start master-B
# docker start slave-A1
# docker start slave-B1
# docker kill slave-C2
# sleep 5

# echo -e "\n==== Final Cluster Info ====\n"
# docker exec master-B redis-cli CLUSTER INFO 2>/dev/null | grep -E "(cluster_state|cluster_slots_assigned|cluster_known_nodes|cluster_size)"
# sleep 1

# echo -e "\n==== Final Cluster Nodes ====\n"
# docker exec master-B redis-cli CLUSTER NODES 2>/dev/null | awk '{print $2, $3}' | sort
# sleep 1

# echo -e "\n==== Final Key Check ====\n"
# for key in "${TEST_KEYS[@]}"; do
#     echo -e "Key-${key}:"
#     docker exec master-B redis-cli -c get "key-${key}" 2>/dev/null
# done
