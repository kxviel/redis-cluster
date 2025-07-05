#!/bin/bash

echo -e "Stopping any existing containers: \n"
docker compose -p redis-cluster down

echo -e "Composing Docker Network: \n"
docker compose -p redis-cluster up -d

sleep 5

echo -e "\nCreating Redis Cluster with 9 nodes (3 masters, 6 slaves): \n"
docker exec master-A redis-cli --cluster create \
  master-A:6379 master-B:6379 master-C:6379 \
  --cluster-yes

sleep 1
docker exec slave-A1 redis-cli --cluster add-node \
  slave-A1:6379 master-A:6379 --cluster-slave

sleep 1
docker exec slave-A2 redis-cli --cluster add-node \
  slave-A2:6379 master-A:6379 --cluster-slave

sleep 1
docker exec slave-B1 redis-cli --cluster add-node \
  slave-B1:6379 master-B:6379 --cluster-slave

sleep 1
docker exec slave-B2 redis-cli --cluster add-node \
  slave-B2:6379 master-B:6379 --cluster-slave

sleep 1
docker exec slave-C1 redis-cli --cluster add-node \
  slave-C1:6379 master-C:6379 --cluster-slave

sleep 1
docker exec slave-C2 redis-cli --cluster add-node \
  slave-C2:6379 master-C:6379 --cluster-slave

sleep 2
echo -e "\nConnecting to Redis Cluster: \n"
docker exec -it master-A redis-cli -c -p 6379