echo -e "Composing Docker Network: \n"

docker-compose up -d

sleep 10

echo -e "\nCreating Redis Cluster: \n"

docker exec master-A redis-cli --cluster create \
  localhost:8080 localhost:8081 localhost:8082 \
  localhost:8083 localhost:8084 localhost:8085 \
  localhost:8086 localhost:8087 localhost:8088 \
  --cluster-replicas 2 --cluster-yes

echo -e "\nConnecting to Redis Cluster: \n"

docker exec -it master-A redis-cli -c -p 8080
