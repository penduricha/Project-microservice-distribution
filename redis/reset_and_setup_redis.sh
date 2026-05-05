#!/bin/bash

# Configuration Variables
USER="default"
PASSWORD="1234"
MAX_MEMORY="2gb"
START_PORT=6379
END_PORT=$((6379 + 7))  # Total 8 shards
IP_ADDRESS="127.0.0.1"

echo "PHASE 1: Hard Reset Redis Instances"

# 1. Kill all redis processes to free up ports
echo "Stopping all redis-server processes..."
pkill -9 redis-server

# 2. Clean up specific ports just in case
for port in $(seq $START_PORT $END_PORT); do
    PID=$(lsof -t -i:$port)
    if [ ! -z "$PID" ]; then
        echo "Forcing close on port $port (PID: $PID)..."
        kill -9 $PID
    fi
done

# 3. Wipe old metadata and database files
echo "Deleting old configuration and data files..."
rm -f redis_*.conf nodes_*.conf redis_*.log redis_*.pid appendonly_*.aof dump_*.rdb

echo "Cleanup finished."
echo ""

echo "Initializing 8 Shards for 'drug-cache'"

for port in $(seq $START_PORT $END_PORT); do
    echo "Starting shard on port: $port..."
    
    cat <<EOF > redis_${port}.conf
port ${port}
cluster-enabled yes
cluster-config-file nodes-${port}.conf
cluster-node-timeout 5000
appendonly yes
appendfilename "appendonly_${port}.aof"
dbfilename "dump_${port}.rdb"
# Security configuration
requirepass ${PASSWORD}
masterauth ${PASSWORD}
# Resource management for your 32GB RAM
maxmemory ${MAX_MEMORY}
maxmemory-policy allkeys-lru
bind 0.0.0.0
daemonize yes
logfile "redis_${port}.log"
pidfile "redis_${port}.pid"
EOF

    redis-server redis_${port}.conf
    
    if [ $? -eq 0 ]; then
        echo "Shard $port is UP."
    else
        echo "ERROR: Could not start Shard $port."
    fi
done

echo ""
echo "--- PHASE 3: Cluster Assembly ---"
# Constructing the cluster command
COMMAND="redis-cli -u redis://$USER:$PASSWORD@$IP_ADDRESS:$START_PORT --cluster create "
for port in $(seq $START_PORT $END_PORT); do
    COMMAND+="$IP_ADDRESS:$port "
done
COMMAND+="--cluster-replicas 0 --cluster-yes"

echo "All shards are running in the background."
echo "Running cluster creation command now..."

eval $COMMAND

echo "Redis Cluster for 'drug-cache' is ready!"
echo "Verify status with: redis-cli -p $START_PORT -a $PASSWORD cluster nodes"