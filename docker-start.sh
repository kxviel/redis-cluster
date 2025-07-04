echo -e "Composing Docker Network: \n"

docker-compose up -d

sleep 5

echo -e "\nCreating Redis Cluster: \n"

docker exec master-A redis-cli --cluster create \
  master-A:8080 master-B:8081 master-C:8082 \
  slave-A1:8083 slave-A2:8084 slave-B1:8085 \
  slave-B2:8086 slave-C1:8087 slave-C2:8088 \
  --cluster-replicas 2 --cluster-yes

echo -e "\nConnecting to Redis Cluster: \n"

docker exec -it master-A redis-cli -c -p 8080

