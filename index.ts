import { createCluster, type RedisClusterOptions } from "redis";

const clusterConfig: RedisClusterOptions = {
  rootNodes: [
    { url: "redis://localhost:8080" },
    { url: "redis://localhost:8081" },
    { url: "redis://localhost:8082" },
  ],
  defaults: {
    socket: {
      connectTimeout: 10000,
    },
  },
};

const runClients = async () => {
  try {
    const cluster = createCluster(clusterConfig);

    // Set up event listeners BEFORE connecting
    cluster.on("error", (err) => console.log("Redis Cluster Error:", err));
    cluster.on("ready", () => {
      console.log("✅ Redis Cluster is ready!");
    });
    cluster.on("connect", () => {
      console.log("🔗 Connected to Redis Cluster");
    });
    cluster.on("reconnecting", () => {
      console.log("🔄 Reconnecting to Redis Cluster");
    });

    // Connect to the cluster
    await cluster.connect();

    // Test the cluster
    await cluster.set("test-key", "Hello Redis Cluster!");
    const value = await cluster.get("test-key");
    console.log("Retrieved value:", value);

    // Close the connection when done
    // await cluster.disconnect();
  } catch (error) {
    console.error("Failed to connect to Redis cluster:", error);
  }
};

runClients();
