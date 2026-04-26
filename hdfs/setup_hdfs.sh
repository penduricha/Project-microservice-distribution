#!/bin/bash
sudo docker-compose down

echo "Kill port 9000"
# Tìm PID của tiến trình đang dùng cổng 9000
PORT_PID=$(sudo lsof -t -i:9000)

if [ -z "$PORT_PID" ]; then
    echo "Port 9000 is empty"
else
    echo "Port $PORT_PID is already used. Killing..."
    sudo kill -9 $PORT_PID
    sleep 5
    echo "Killed port 9000."
fi

echo "Granting access"
sudo chmod -R 777 ./data-node ./name-node ./data-input

# DỌN DẸP VÀ KHỞI TẠO LẠI 
echo "Cleaning HDFS old and restarting"
sudo docker-compose down -v  
sudo docker-compose up -d

# Đợi NameNode khởi động
echo "Waiting 1 minute"
sleep 60

# --- BƯỚC 3: KIỂM TRA PHÂN CỤM ---
echo "Status HDFS"
sudo docker exec namenode hdfs dfsadmin -report | grep -E "Live nodes|Name|Hostname"

# --- BƯỚC 4: NẠP DATA ---
sudo docker exec namenode hdfs dfs -mkdir -p /user/data/drug
sudo docker cp "data-input/drug200.csv" namenode:/tmp/drug200.csv
sudo docker exec namenode hdfs dfs -put -f /tmp/drug200.csv /user/data/drug

echo "Waiting 2 minutes"
sleep 120

echo "Done"
sudo docker exec namenode hdfs dfs -ls /user/data/drug