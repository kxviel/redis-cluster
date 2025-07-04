import { createCluster, RedisClusterOptions } from "redis";

const clusterConfig: RedisClusterOptions = {
  rootNodes: [
    { url: "redis://localhost:8080" },
    { url: "redis://localhost:8081" },
    { url: "redis://localhost:8082" },
    { url: "redis://localhost:8083" },
    { url: "redis://localhost:8084" },
    { url: "redis://localhost:8085" },
    { url: "redis://localhost:8086" },
    { url: "redis://localhost:8087" },
    { url: "redis://localhost:8088" },
  ],
};

const runClients = async () => {
  const cluster = await createCluster(clusterConfig)
    .on("error", (err) => console.log("Redis Cluster Error", err))
    .connect();

  cluster.on("ready", () => {
    console.log("HEY YOPOOOOOOOOOOOOOOOO");
  });
};

runClients();
