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

    await cluster.connect();
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
