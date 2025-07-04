#!/bin/bash

echo -e "Stopping any existing containers: \n"

docker compose -p redis-cluster down

echo -e "Composing Docker Network: \n"

docker compose -p redis-cluster up -d

sleep 10

echo -e "\nCreating Redis Cluster with 6 nodes (3 masters, 3 slaves): \n"

# Use only 6 nodes for a proper 3-master, 6-slave setup
docker exec master-A redis-cli --cluster create \
  master-A:6379 master-B:6379 master-C:6379 \
  slave-A1:6379 slave-B1:6379 slave-C1:6379 \
  slave-A2:6379 slave-B2:6379 slave-C2:6379 \
  --cluster-replicas 2 --cluster-yes

sleep 10

# echo -e "\nCluster Info: \n"

# docker exec master-A redis-cli -p 6379 cluster info

# echo -e "\nCluster Nodes: \n"

# docker exec master-A redis-cli -p 6379 cluster nodes

# echo -e "\nTesting cluster: \n"

# docker exec master-A redis-cli -c -p 6379 set key1 "value1"
# docker exec master-A redis-cli -c -p 6379 set key2 "value2"
# docker exec master-A redis-cli -c -p 6379 set key3 "value3"
# docker exec master-A redis-cli -c -p 6379 get key1
# docker exec master-A redis-cli -c -p 6379 get key2
# docker exec master-A redis-cli -c -p 6379 get key3

echo -e "\nConnecting to Redis Cluster: \n"

docker exec -it master-A redis-cli -c -p 6379