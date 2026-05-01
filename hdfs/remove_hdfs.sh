#!/bin/bash

# Danh sách các port cần giải phóng cho HDFS (NameNode, DataNodes, Web UI)
# 9000: HDFS RPC, 9870: NameNode UI, 9864-9867: DataNodes UI, 8088: YARN UI
PORTS=(9000 9870 9864 9865 9866 9867 8088)

DATA_DIRS=("node1" "node2" "node3" "node4")

echo "1. Stopping Docker containers and cleaning volumes..."
sudo docker-compose down -v --remove-orphans
sleep 5

echo "2. Cleaning HDFS directories..."
sudo rm -rf name-node/* data-node/*
mkdir -p name-node
for dir in "${DATA_DIRS[@]}"; do
    mkdir -p "data-node/$dir"
done

echo "3. Killing processes on HDFS ports..."
for PORT in "${PORTS[@]}"; do
    PORT_PID=$(sudo lsof -t -i:$PORT)
    if [ -z "$PORT_PID" ]; then
        echo "Port $PORT is free."
    else
        echo "Port $PORT is occupied by PID: $PORT_PID. Killing process..."
        sudo kill -9 $PORT_PID
        sleep 2
    fi
done

echo "Done! Ready for docker-compose up."