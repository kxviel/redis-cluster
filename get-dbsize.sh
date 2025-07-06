#!/bin/bash

echo -e "\nMaster-A: $(docker exec -it master-A redis-cli dbsize)"
sleep 1

echo -e "Slave-A1: $(docker exec -it slave-A1 redis-cli dbsize)"
sleep 1

echo -e "Slave-A2: $(docker exec -it slave-A2 redis-cli dbsize)"
sleep 1

echo -e "\nMaster-B: $(docker exec -it master-B redis-cli dbsize)"
sleep 1

echo -e "Slave-B1: $(docker exec -it slave-B1 redis-cli dbsize)"
sleep 1

echo -e "Slave-B2: $(docker exec -it slave-B2 redis-cli dbsize)"
sleep 1

echo -e "\nMaster-C: $(docker exec -it master-C redis-cli dbsize)"
sleep 1

echo -e "Slave-C1: $(docker exec -it slave-C1 redis-cli dbsize)"
sleep 1

echo -e "Slave-C2: $(docker exec -it slave-C2 redis-cli dbsize)"
sleep 1

MASTER_A=$(docker exec master-A redis-cli dbsize)
MASTER_B=$(docker exec master-B redis-cli dbsize)
MASTER_C=$(docker exec master-C redis-cli dbsize)
TOTAL=$((MASTER_A + MASTER_B + MASTER_C))
echo -e "\nTotal Keys: $TOTAL\n"
sleep 1