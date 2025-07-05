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

    cluster.on("error", (e) => {
      console.log("Damnit: ", e);
    });

    cluster.on("ready", () => {
      console.log("Works");
    });

    cluster.on("connect", () => {
      console.log("Connected");
    });

    cluster.on("end", () => {
      console.log("End");
    });

    console.log("Connecting to Redis cluster...");

    // Connect to the cluster
    await cluster.connect();
    await replicationTest(cluster);
  } catch (error) {
    console.error("Failed to connect to Redis cluster:", error);
    throw error;
  }
};

const replicationTest = async (cluster: any) => {
  console.log("Testing Replication: ");

  console.log("Inserting 1mil Keys... ");
  console.log("might take a bit");
  for (let i = 0; i < 1000000; i++) {
    await cluster.set(`key-${i}`, i);
  }

  console.log("less goooo");
};

runClients();
