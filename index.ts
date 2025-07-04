import { createCluster, type RedisClusterOptions } from "redis";

const clusterConfig: RedisClusterOptions = {
  rootNodes: [
    { url: "redis://master-A:6379" },
    { url: "redis://master-B:6379" },
    { url: "redis://master-C:6379" },
  ],
  defaults: {
    socket: {
      connectTimeout: 10000,
    },
  },
  useReplicas: true,
};

const runClients = async () => {
  try {
    let cluster = createCluster(clusterConfig);

    // Set up event listeners BEFORE connecting
    cluster.on("error", (e) => {
      console.log("Damn: ", e);
    });

    cluster.on("ready", () => {
      console.log("Works - Redis Cluster is ready!");
    });

    cluster.on("connect", () => {
      console.log("Connected to Redis Cluster");
    });

    cluster.on("reconnecting", () => {
      console.log("Reconnecting to Redis Cluster");
    });

    cluster.on("end", () => {
      console.log("Redis Cluster connection ended");
    });

    console.log("Attempting to connect to Redis cluster...");

    // Connect to the cluster
    await cluster.connect();

    console.log("Inserting 1mil Keys lmao");

    // Test the cluster with some operations
    await cluster.set("test:key1", "Hello from Redis Cluster!");
    await cluster.set("test:key2", "Another test value");

    const value1 = await cluster.get("test:key1");
    const value2 = await cluster.get("test:key2");

    console.log("Retrieved values:");
    console.log("test:key1 =", value1);
    console.log("test:key2 =", value2);

    console.log("✅ All operations completed successfully!");

    // Keep the connection alive for testing
    console.log("Keeping connection alive... Press Ctrl+C to exit");
  } catch (error) {
    console.error("Failed to connect to Redis cluster:", error);
    throw error;
  }
};

runClients();
