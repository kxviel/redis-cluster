#!/bin/bash

echo -e "Stop existing containers: \n"
docker compose -p redis-cluster down

echo -e "Composing Docker Network: \n"
docker compose -p redis-cluster up -d

echo -e "Starting Containers: \n"
sleep 10

echo -e "\nCreating Redis Cluster with 9 nodes (3 masters, 6 slaves): \n"
docker exec master-A redis-cli --cluster create \
  master-A:6379 master-B:6379 master-C:6379 \
  --cluster-yes

echo -e "\nWaiting for master cluster to stabilize...\n"
sleep 3

MASTER_A_ID=$(docker exec master-A redis-cli cluster nodes | grep "master-A:6379@" | grep "master" | awk '{print $1}')
MASTER_B_ID=$(docker exec master-B redis-cli cluster nodes | grep "master-B:6379@" | grep "master" | awk '{print $1}')
MASTER_C_ID=$(docker exec master-C redis-cli cluster nodes | grep "master-C:6379@" | grep "master" | awk '{print $1}')



docker exec slave-A1 redis-cli --cluster add-node \
  slave-A1:6379 master-A:6379 --cluster-slave --cluster-master-id $MASTER_A_ID

sleep 2

docker exec slave-A2 redis-cli --cluster add-node \
  slave-A2:6379 master-A:6379 --cluster-slave --cluster-master-id $MASTER_A_ID

sleep 2

docker exec slave-B1 redis-cli --cluster add-node \
  slave-B1:6379 master-B:6379 --cluster-slave --cluster-master-id $MASTER_B_ID

sleep 2

docker exec slave-B2 redis-cli --cluster add-node \
  slave-B2:6379 master-B:6379 --cluster-slave --cluster-master-id $MASTER_B_ID

sleep 2

docker exec slave-C1 redis-cli --cluster add-node \
  slave-C1:6379 master-C:6379 --cluster-slave --cluster-master-id $MASTER_C_ID

sleep 2

docker exec slave-C2 redis-cli --cluster add-node \
  slave-C2:6379 master-C:6379 --cluster-slave --cluster-master-id $MASTER_C_ID

sleep 5

# echo -e "\nChecking cluster status:\n"
# docker exec master-A redis-cli --cluster check master-A:6379

# echo -e "\nCluster nodes:\n"
# docker exec master-A redis-cli cluster nodes

# echo -e "\nCluster info:\n"
# docker exec master-A redis-cli cluster info

# echo -e "\nCluster setup complete! You can now run your application.\n"
# echo -e "To connect to the cluster manually:\n"
# echo -e "docker exec -it master-A redis-cli -c -p 6379\n"