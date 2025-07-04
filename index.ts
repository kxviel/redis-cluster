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
  useReplicas: true, // Enable reading from replicas
};

const runClients = async () => {
  let cluster;

  try {
    cluster = createCluster(clusterConfig);

    // Set up event listeners BEFORE connecting
    cluster.on("error", (err) => {
      console.log("Redis Cluster Error:", err);
    });

    cluster.on("ready", () => {
      console.log("✅ Redis Cluster is ready!");
    });

    cluster.on("connect", () => {
      console.log("🔗 Connected to Redis Cluster");
    });

    cluster.on("reconnecting", () => {
      console.log("🔄 Reconnecting to Redis Cluster");
    });

    cluster.on("end", () => {
      console.log("🔌 Redis Cluster connection ended");
    });

    // Connect to the cluster
    await cluster.connect();

    // Test the cluster with some operations
    console.log("Testing cluster operations...");

    // Set some test keys
    await cluster.set("test:key1", "Hello from Redis Cluster!");
    await cluster.set("test:key2", "Another test value");
    await cluster.set(
      "test:key3",
      JSON.stringify({ message: "JSON data", timestamp: Date.now() })
    );

    // Get the values back
    const value1 = await cluster.get("test:key1");
    const value2 = await cluster.get("test:key2");
    const value3 = await cluster.get("test:key3");

    console.log("Retrieved values:");
    console.log("test:key1 =", value1);
    console.log("test:key2 =", value2);
    console.log("test:key3 =", value3);

    // Test hash operations
    await cluster.hSet("test:hash", {
      field1: "value1",
      field2: "value2",
      field3: "value3",
    });

    const hashValues = await cluster.hGetAll("test:hash");
    console.log("Hash values:", hashValues);

    console.log("✅ All operations completed successfully!");
  } catch (error) {
    console.error("Failed to connect to Redis cluster:", error);
  } finally {
    // Properly close the connection
    if (cluster) {
      try {
        await cluster.quit(); // Use quit() instead of disconnect()
        console.log("🔌 Redis Cluster connection closed gracefully");
      } catch (closeError) {
        console.error("Error closing cluster connection:", closeError);
      }
    }
  }
};

// Handle process termination
process.on("SIGINT", async () => {
  console.log("\n🛑 Shutting down gracefully...");
  process.exit(0);
});

process.on("SIGTERM", async () => {
  console.log("\n🛑 Shutting down gracefully...");
  process.exit(0);
});

runClients();
