# #!/bin/bash
# sudo rm -rf name-node/*
# sudo rm -rf data-node/* 

# sudo docker-compose down

# sudo docker rm -f namenode datanode1 datanode2 datanode3 datanode4

# echo "Kill port 9000"
# # Tìm PID của tiến trình đang dùng cổng 9000
# PORT_PID=$(sudo lsof -t -i:9000)

# if [ -z "$PORT_PID" ]; then
#     echo "Port 9000 is empty"
# else
#     echo "Port $PORT_PID is already used. Killing..."
#     sudo kill -9 $PORT_PID
#     sleep 5
#     echo "Killed port 9000."
# fi

# sleep 60

# echo "Granting access"
# sudo chmod -R 777 ./data-node ./name-node ./data-input

# # Dọn dẹp và khởi tạo lại
# echo "Cleaning HDFS old and restarting"

# mkdir data-node/node1/ data-node/node2/ data-node/node3/ data-node/node4/

# sudo docker-compose down -v  

# # Kết thúc dọn dẹp.
# sleep 30

# docker-compose run namenode hdfs namenode -format

# sudo docker-compose up -d

# # Đợi NameNode khởi động
# echo "Waiting 3 minutes"
# sleep 180

# # Kiểm tra phân cụm
# echo "Status HDFS"
# sudo docker exec namenode hdfs dfsadmin -report | grep -E "Live nodes|Name|Hostname"

# # --- BƯỚC 4: NẠP DATA ---
# sudo docker exec namenode hdfs dfs -mkdir -p /user/data/drug
# sudo docker cp "data-input/drug200.csv" namenode:/tmp/drug200.csv
# sudo docker exec namenode hdfs dfs -put -f /tmp/drug200.csv /user/data/drug

# echo "Waiting 3 minutes"
# sleep 180

# echo "Done"
# sudo docker exec namenode hdfs dfs -ls /user/data/drug

#!/bin/bash

# CONFIGURATION 
DATA_DIRS=("node1" "node2" "node3" "node4")

echo "1. Cleaning up old system"
# Remove volumes and orphans to ensure a fresh start
sudo docker-compose down -v --remove-orphans

# Force remove directories and recreate them
sudo rm -rf name-node/* data-node/*

mkdir -p name-node
for dir in "${DATA_DIRS[@]}"; do
    mkdir -p "data-node/$dir"
done

echo "2. Checking Port 9000"
PORT_PID=$(sudo lsof -t -i:9000)
if [ -z "$PORT_PID" ]; then
    echo "Port 9000 is free."
else
    echo "Port 9000 is occupied by PID: $PORT_PID. Killing process..."
    sudo kill -9 $PORT_PID
    sleep 10
fi

# Grant permissions
echo "Granting permissions..."
sudo chmod -R 777 ./data-node ./name-node ./data-input

echo "3. Formatting NameNode"
# Format the namenode - this is critical for the "NameNode is not formatted" error
docker-compose run --rm namenode hdfs namenode -format

echo "4. Starting HDFS Cluster"
sudo docker-compose up -d

echo "5. Waiting for NameNode to be ready"
# Check NameNode Web UI status instead of fixed sleep
until $(curl --output /dev/null --silent --head --fail http://localhost:9870); do
    printf '.'
    sleep 10
done
echo -e "\nNameNode Web UI is active!"

# Leave Safe Mode if necessary
echo "Ensuring NameNode leaves Safe Mode..."
sleep 20
sudo docker exec namenode hdfs dfsadmin -safemode leave

echo "6. HDFS Cluster Report"
sudo docker exec namenode hdfs dfsadmin -report | grep -E "Live nodes|Name|Hostname"

echo "7. Data Ingestion"
# Create HDFS directory
sudo docker exec namenode hdfs dfs -mkdir -p /user/data/drug

# Upload file
if [ -f "data-input/drug200.parquet" ]; then
    echo "Uploading drug200.csv to HDFS..."
    sudo docker cp "data-input/drug200.parquet" namenode:/tmp/drug200.parquet
    sudo docker exec namenode hdfs dfs -put -f /tmp/drug200.parquet /user/data/drug
    echo "Ingestion completed successfully."
else
    echo "Warning: data-input/drug200.csv not found. Skipping upload."
fi

echo "8. Verifying HDFS Content"
sudo docker exec namenode hdfs dfs -ls /user/data/drug

echo "Setup Process Finished"