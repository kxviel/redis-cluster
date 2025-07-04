echo -e "Composing Docker Network: \n"

docker-compose up -d

sleep 10

# docker exec master-A redis-cli --cluster create \
#   master-A:8080 master-B:8081 master-C:8082 \
#   slave-A1:8083 slave-A2:8084 slave-B1:8085 \
#   slave-B2:8086 slave-C1:8087 slave-C2:8088 \
#   --cluster-replicas 2 --cluster-yes

echo -e "\nCreating Redis Cluster Masters: \n"

docker exec master-A redis-cli --cluster create \
  localhost:8080 localhost:8081 localhost:8082  \
  --cluster-yes

echo -e "\nCreating Redis Cluster Slaves: \n"

docker exec master-A redis-cli --cluster add-node localhost:8083 localhost:8080 --cluster-slave
docker exec master-A redis-cli --cluster add-node localhost:8084 localhost:8080 --cluster-slave
docker exec master-A redis-cli --cluster add-node localhost:8085 localhost:8081 --cluster-slave  
docker exec master-A redis-cli --cluster add-node localhost:8086 localhost:8081 --cluster-slave
docker exec master-A redis-cli --cluster add-node localhost:8087 localhost:8082 --cluster-slave
docker exec master-A redis-cli --cluster add-node localhost:8088 localhost:8082 --cluster-slave


echo -e "\nCluster Nodes: \n"

docker exec master-A redis-cli -p 6379 cluster nodes

echo -e "\nConnecting to Redis Cluster: \n"

docker exec -it master-A redis-cli -c -p 6379

