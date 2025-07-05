#!/bin/bash

echo "=== REDIS CLUSTER CRASH TESTS ==="

# Function to get cluster status
get_cluster_status() {
    echo -e "\n=== Cluster Status ==="
    if docker exec master-B redis-cli cluster nodes 2>/dev/null; then
        return 0
    elif docker exec master-C redis-cli cluster nodes 2>/dev/null; then
        return 0
    else
        echo "❌ Cannot get cluster status from any master"
        return 1
    fi
}

# Function to check random keys
check_random_keys() {
    echo -e "\n=== Checking 10 Random Keys ==="
    local missing_count=0
    
    for i in {1..10}; do
        local random_key="key-$((RANDOM % 1000000))"
        if docker exec redis-client node -e "
            const { createCluster } = require('redis');
            const cluster = createCluster({
                rootNodes: [
                    { url: 'redis://master-A:6379' },
                    { url: 'redis://master-B:6379' },
                    { url: 'redis://master-C:6379' }
                ],
                useReplicas: true
            });
            cluster.connect().then(async () => {
                try {
                    const value = await cluster.get('$random_key');
                    if (value === null) {
                        console.log('❌ $random_key: MISSING');
                        process.exit(1);
                    } else {
                        console.log('✅ $random_key: ' + value);
                        process.exit(0);
                    }
                } catch (error) {
                    console.log('❌ $random_key: ERROR - ' + error.message);
                    process.exit(1);
                }
            }).catch(error => {
                console.log('❌ $random_key: CONNECTION ERROR');
                process.exit(1);
            });
        " 2>/dev/null; then
            echo "Key found"
        else
            ((missing_count++))
        fi
        sleep 1
    done
    
    echo "Summary: $((10 - missing_count))/10 keys found"
    if [ $missing_count -gt 0 ]; then
        echo "Missing keys: $missing_count"
    fi
}

# Test 1: Crash one master
echo -e "\n\n=== TEST 1: CRASH MASTER TEST ==="
get_cluster_status

echo -e "\nCrashing Master B..."
docker kill master-B
sleep 5

get_cluster_status
check_random_keys

# Test 2: Crash multiple nodes (keep one from each group)
echo -e "\n\n=== TEST 2: CRASH MULTIPLE NODES TEST ==="
echo "Crashing all but one node from each group..."
echo "Keeping: master-A, slave-B1, slave-C1"

docker kill slave-A1
sleep 2
docker kill slave-A2  
sleep 2
docker kill slave-B2
sleep 2
docker kill slave-C2
sleep 5

get_cluster_status
check_random_keys

# Test 3: Crash entire group
echo -e "\n\n=== TEST 3: CRASH ENTIRE GROUP TEST ==="
echo "Crashing entire group C (master-C, slave-C1)..."

docker kill master-C
docker kill slave-C1
sleep 5

get_cluster_status
check_random_keys

echo -e "\n=== TEST RESULTS SUMMARY ==="
echo "✅ Master crash test: Completed"
echo "✅ Multiple nodes crash test: Completed"
echo "✅ Entire group crash test: Completed"
echo ""
echo "Note: Run 'docker compose -p redis-cluster up -d' to restart crashed containers"