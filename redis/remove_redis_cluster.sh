# Configuration
PASSWORD="1234"
# Using static IPs from the redis_isolated_node network (172.25.0.x)
NODES="172.25.0.10:6379 172.25.0.11:6379 172.25.0.12:6379 172.25.0.13:6379 172.25.0.14:6379 172.25.0.15:6379 172.25.0.16:6379 172.25.0.17:6379"

echo "Deep cleaning"
# Stop and remove containers, networks, and images defined in compose
docker-compose down --remove-orphans
# Clean local data directories to avoid "Node is not empty" errors
sudo rm -rf ./data/*