#!/bin/bash

echo -e "Stop existing containers: \n"
docker compose -p redis-cluster down

echo -e "Composing Docker Network: \n"
docker compose -p redis-cluster up -d
sleep 5

echo -e "\nCreating Redis Cluster with 3 masters: \n"
docker exec master-A redis-cli --cluster create \
  master-A:6379 master-B:6379 master-C:6379 \
  --cluster-yes

echo -e "\nWaiting for master cluster to stabilize...\n"
sleep 5

echo -e "Getting master node IDs...\n"
MASTER_A_ID=$(docker exec master-A redis-cli cluster nodes | grep "master-A:6379.*master" | awk '{print $1}')
MASTER_B_ID=$(docker exec master-B redis-cli cluster nodes | grep "master-B:6379.*master" | awk '{print $1}')
MASTER_C_ID=$(docker exec master-C redis-cli cluster nodes | grep "master-C:6379.*master" | awk '{print $1}')

echo "Master A ID: $MASTER_A_ID"
echo "Master B ID: $MASTER_B_ID"
echo "Master C ID: $MASTER_C_ID"

echo -e "\nAdding slaves to Master A:\n"
docker exec slave-A1 redis-cli --cluster add-node \
  slave-A1:6379 master-A:6379 --cluster-slave --cluster-master-id $MASTER_A_ID
sleep 2

docker exec slave-A2 redis-cli --cluster add-node \
  slave-A2:6379 master-A:6379 --cluster-slave --cluster-master-id $MASTER_A_ID
sleep 2

echo -e "\nAdding slaves to Master B:\n"
docker exec slave-B1 redis-cli --cluster add-node \
  slave-B1:6379 master-B:6379 --cluster-slave --cluster-master-id $MASTER_B_ID
sleep 2

docker exec slave-B2 redis-cli --cluster add-node \
  slave-B2:6379 master-B:6379 --cluster-slave --cluster-master-id $MASTER_B_ID
sleep 2

echo -e "\nAdding slaves to Master C:\n"
docker exec slave-C1 redis-cli --cluster add-node \
  slave-C1:6379 master-C:6379 --cluster-slave --cluster-master-id $MASTER_C_ID
sleep 2

docker exec slave-C2 redis-cli --cluster add-node \
  slave-C2:6379 master-C:6379 --cluster-slave --cluster-master-id $MASTER_C_ID

echo -e "\nWaiting for cluster to stabilize...\n"
sleep 3

echo -e "Redis Cluster setup complete!\n"
echo "Cluster status:"
docker exec master-A redis-cli cluster nodes

echo -e "\nVerifying slave assignments:"
echo "Master A slaves: $(docker exec master-A redis-cli cluster nodes | grep "slave.*$MASTER_A_ID" | wc -l)"
echo "Master B slaves: $(docker exec master-B redis-cli cluster nodes | grep "slave.*$MASTER_B_ID" | wc -l)"
echo "Master C slaves: $(docker exec master-C redis-cli cluster nodes | grep "slave.*$MASTER_C_ID" | wc -l)"