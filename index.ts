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
    await availabilityTest(cluster);

    await crashMultipleNodes(cluster);
    await crashOneWholeNode(cluster);
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
  console.log("Testing Replication: ");

  console.log("Inserting 1mil Keys... ");
  console.log("might take a bit");
  for (let i = 0; i < 1000000; i++) {
    await cluster.set(`key-${i}`, i);
  }

  await new Promise((resolve) => setTimeout(resolve, 2000));
  console.log("Getting dbsize of all masters and slaves: ");
  execCommand("bash get-dbsize.sh");
  await new Promise((resolve) => setTimeout(resolve, 2000));
};

const availabilityTest = async (cluster: any) => {
  console.log("Testing Availability: ");

  console.log("Crashing Master A: docker kill master-A");
  execCommand("docker kill master-A");
  await new Promise((resolve) => setTimeout(resolve, 2000));

  await getClusterStatus();
  await checkRandomKeys(cluster);
  await new Promise((resolve) => setTimeout(resolve, 2000));
};

const getClusterStatus = async () => {
  try {
    const result = await execCommand(
      "docker exec master-B redis-cli cluster nodes"
    );
    console.log("\nCluster Status: ");
    console.log(result);
    return result;
  } catch (error) {
    console.log(
      "Failed to get cluster status from master-B, trying master-C..."
    );

    try {
      const result = await execCommand(
        "docker exec master-C redis-cli cluster nodes"
      );
      console.log("\nCluster Status: ");
      console.log(result);
      return result;
    } catch (error2) {
      console.log("Failed to get cluster status from both masters");
      return "";
    }
  }
};

const checkRandomKeys = async (cluster: any) => {
  console.log("\nChecking 10 Random Keys: ");
  const randomKeys = [];
  const missingKeys = [];

  for (let i = 0; i < 10; i++) {
    const randomId = Math.floor(Math.random() * 1000000);
    randomKeys.push(`key-${randomId}`);
  }

  for (const key of randomKeys) {
    try {
      const value = await cluster.get(key);
      if (value === null) {
        missingKeys.push(key);
        console.log(`${key}: MISSING`);
      } else {
        console.log(`${key}: ${value}`);
      }
    } catch (error) {
      missingKeys.push(key);
      console.log(`${key} - ERROR: ${error}`);
    }
  }

  console.log(
    `\nSummary: ${randomKeys.length - missingKeys.length}/${
      randomKeys.length
    } keys found`
  );
  if (missingKeys.length > 0) {
    console.log(`Missing keys: ${missingKeys.join(", ")}`);
  }

  return missingKeys;
};

const crashMultipleNodes = async (cluster: any) => {
  console.log("Crashing all but one node from each group...");

  // master-A has been already crashed, so working nodes: slave-A1, slave-B1, slave-C1
  const nodesToCrash = [
    "master-B",
    "master-C",
    "slave-A2",
    "slave-B2",
    "slave-C2",
  ];

  for (const node of nodesToCrash) {
    console.log(`Crashing ${node}...`);
    await execCommand(`docker kill ${node}`);
    await new Promise((resolve) => setTimeout(resolve, 2000));
  }

  await new Promise((resolve) => setTimeout(resolve, 2000));

  await getClusterStatus();
  await checkRandomKeys(cluster);
  await new Promise((resolve) => setTimeout(resolve, 2000));
};

const crashOneWholeNode = async (cluster: any) => {
  console.log("Crashing all from A...");

  await execCommand("docker kill slave-A1");
  await new Promise((resolve) => setTimeout(resolve, 2000));

  await getClusterStatus();
  await checkRandomKeys(cluster);
  await new Promise((resolve) => setTimeout(resolve, 2000));
};

runClients();
