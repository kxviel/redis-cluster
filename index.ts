import { exec } from "child_process";
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
    // await availabilityTest(cluster);

    // await crashMultipleNodes(cluster);
    // await crashOneWholeNode(cluster);
  } catch (error) {
    console.error("Failed to connect to Redis cluster:", error);
    throw error;
  }
};

const execCommand = (command: string): Promise<string> => {
  return new Promise((resolve, reject) => {
    exec(command, (err, stdout, stderr) => {
      if (err) {
        console.error(`Error executing ${command}:`, stderr);
        return reject(err);
      }
      resolve(stdout);
    });
  });
};

const replicationTest = async (cluster: any) => {
  console.log("Inserting 1 mil Keys, might take a while...");

  const batchSize = 1000;

  for (let i = 0; i < 1000000; i += batchSize) {
    const multi = cluster.multi();
    const endIndex = Math.min(i + batchSize, 1000000);

    for (let j = i; j < endIndex; j++) {
      multi.set(`key-${j}`, j.toString());
    }

    await multi.exec();

    if (i % 100000 === 0) {
      console.log(`Inserted ${i + batchSize} keys...`);
    }
  }

  console.log("Done inserting keys. Checking replication...");

  try {
    await execCommand("bash get-dbsize.sh");
  } catch (error) {
    console.error("Error getting database size:", error);
  }
};

runClients();
