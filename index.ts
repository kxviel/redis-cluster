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

    console.log("Inserting 1mil Keys lmao, wait bitte ... ");
    for (let i = 0; i < 1000000; i++) {
      await cluster.set(`test:key${i}`, i + 1);
    }

    console.log("Done inserting 1 million keys!");
  } catch (error) {
    console.error("Failed to connect to Redis cluster:", error);
    throw error;
  }
};

runClients();
