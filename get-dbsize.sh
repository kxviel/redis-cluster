#!/bin/bash

docker exec -it master-A redis-cli dbsize
sleep 2

docker exec -it slave-A1 redis-cli dbsize
sleep 2

docker exec -it slave-A2 redis-cli dbsize
sleep 2

docker exec -it master-B redis-cli dbsize
sleep 2

docker exec -it slave-B1 redis-cli dbsize
sleep 2

docker exec -it slave-B2 redis-cli dbsize
sleep 2

docker exec -it master-C redis-cli dbsize
sleep 2

docker exec -it slave-C1 redis-cli dbsize
sleep 2

docker exec -it slave-C2 redis-cli dbsize
sleep 2