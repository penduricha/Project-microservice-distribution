#!/bin/bash

# Configuration
PASSWORD="1234"
# Using static IPs from the redis_isolated_node network (172.25.0.x)
NODES="172.25.0.10:6379 172.25.0.11:6379 172.25.0.12:6379 172.25.0.13:6379 172.25.0.14:6379 172.25.0.15:6379 172.25.0.16:6379 172.25.0.17:6379"

echo "Deep cleaning"
# Stop and remove containers, networks, and images defined in compose
docker-compose down --remove-orphans
# Clean local data directories to avoid "Node is not empty" errors
sudo rm -rf ./data/*

echo "Building Image and Starting Services"
# Rebuild image to ensure redis.conf is updated inside the container
docker-compose up -d --build

echo "Waiting for Redis nodes to be ready (12 seconds)..."
sleep 12

echo "Initializing Redis Cluster"
# Execute cluster creation from within the first container
docker exec -it redis-6380 redis-cli -a $PASSWORD --cluster create $NODES --cluster-replicas 0 --cluster-yes

echo ""
echo "--- STEP 4: Checking Cluster Status ---"
# Verify all shards are connected and slots are assigned
docker exec -it redis-6380 redis-cli -a $PASSWORD cluster nodes

echo ""
echo "Deployment completed! Drug-cache system is ready on ports 6380-6387."