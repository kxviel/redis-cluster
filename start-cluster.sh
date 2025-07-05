#!/bin/bash

echo -e "Stopping any existing containers: \n"
docker compose -p redis-cluster down

echo -e "Composing Docker Network: \n"
docker compose -p redis-cluster up -d

sleep 10

echo -e "\nCreating Redis Cluster with 9 nodes (3 masters, 6 slaves): \n"
docker exec master-A redis-cli --cluster create \
  master-A:6379 master-B:6379 master-C:6379 \
  slave-A1:6379 slave-B1:6379 slave-C1:6379 \
  slave-A2:6379 slave-B2:6379 slave-C2:6379 \
  --cluster-replicas 2 --cluster-yes

sleep 10

echo -e "\nConnecting to Redis Cluster: \n"
docker exec -it master-A redis-cli -c -p 6379