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
      reconnectStrategy: (retries) => Math.min(retries * 50, 500),
    },
  },
  useReplicas: true,
};

const runClients = async () => {
  let cluster;
  try {
    cluster = createCluster(clusterConfig);

    cluster.on("error", (e) => {
      console.log("Cluster error: ", e);
    });

    cluster.on("ready", () => {
      console.log("Cluster ready");
    });

    cluster.on("connect", () => {
      console.log("Connected to cluster");
    });

    cluster.on("end", () => {
      console.log("Cluster connection ended");
    });

    console.log("Connecting to Redis cluster...");

    await cluster.connect();
    await cluster.ping();
    console.log("Cluster ping successful");

    await replicationTest(cluster);
  } catch (error) {
    console.error("Failed to connect to Redis cluster:", error);
    throw error;
  } finally {
    if (cluster) {
      await cluster.close();
    }
  }
};

const replicationTest = async (cluster: any) => {
  console.log("Starting replication test, might take a while...");

  const totalKeys = 1000000;
  const batchSize = 100;

  try {
    for (let i = 0; i < totalKeys; i += batchSize) {
      const endIndex = Math.min(i + batchSize, totalKeys);

      const promises = [];
      for (let j = i; j < endIndex; j++) {
        promises.push(cluster.set(`key-${j}`, j.toString()));
      }

      await Promise.all(promises).then(() => console.log("1 mil Keys Added"));
    }
  } catch (error) {
    console.error("Replication test failed:", error);
    throw error;
  }
};

process.on("SIGINT", () => {
  console.log("Received SIGINT, shutting down gracefully...");
  process.exit(0);
});

runClients();
