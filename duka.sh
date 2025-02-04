#!/bin/bash

# Define color codes for better output visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No color

# Function to print messages in color
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to get the local machine's IP address
get_ip() {
    hostname -I | awk '{print $1}'
}

# Default domain and app name
domain=$(get_ip)
app_name="dujiaoshuka"

# Create necessary directories
mkdir -p dujiao/{storage,uploads,data,redis}
chmod 777 dujiao/{storage,uploads,data,redis}

# Change to the dujiao directory
cd dujiao || exit

# Set MySQL password manually
mysql_pwd="Nic35740olas"
app_key=$(echo "${domain}app" | md5sum | awk '{print $1}')

print_message "$GREEN" "MySQL Password: $mysql_pwd"
print_message "$GREEN" "Application Key: $app_key"

# Create docker-compose.yaml file
cat <<EOF >docker-compose.yaml
version: "3"
services:
  faka:
    image: ghcr.io/apocalypsor/dujiaoka:latest
    container_name: faka
    environment:
        - INSTALL=true
    volumes:
      - ./env.conf:/dujiaoka/.env:rw
      - ./uploads:/dujiaoka/public/uploads:rw
      - ./storage:/dujiaoka/storage:rw
    ports:
      - 3080:80
    restart: always
 
  db:
    image: mariadb:focal
    container_name: faka-data
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=${mysql_pwd}
      - MYSQL_DATABASE=dujiaoka
      - MYSQL_USER=dujiaoka
      - MYSQL_PASSWORD=${mysql_pwd}
    volumes:
      - ./data:/var/lib/mysql:rw

  redis:
    image: redis:alpine
    container_name: faka-redis
    restart: always
    volumes:
      - ./redis:/data:rw
EOF

# Default to no HTTPS
app_url="http://${domain}"

print_message "$YELLOW" "Application URL: ${app_url}:3080"

# Create env.conf file
cat <<EOF > env.conf
APP_NAME=${app_name}
APP_ENV=local
APP_KEY=${app_key}
APP_DEBUG=false
APP_URL=${app_url}:3080
ADMIN_HTTPS=false

LOG_CHANNEL=stack

# Database Configuration
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=dujiaoka
DB_USERNAME=dujiaoka
DB_PASSWORD=${mysql_pwd}

# Redis Configuration
REDIS_HOST=redis
REDIS_PASSWORD=
REDIS_PORT=6379

BROADCAST_DRIVER=log
SESSION_DRIVER=file
SESSION_LIFETIME=120

# Cache Configuration
CACHE_DRIVER=file

# Asynchronous Message Queue
QUEUE_CONNECTION=redis

# Admin Panel Language
## zh_CN Simplified Chinese
## zh_TW Traditional Chinese
## en    English
DUJIAO_ADMIN_LANGUAGE=en

# Admin Panel Login Path
ADMIN_ROUTE_PREFIX=/admin
EOF

chmod 777 env.conf

# Start the containers
print_message "$GREEN" "Starting containers..."
docker-compose up -d 

# Print final message
cat << EOF

$(print_message "$GREEN" "Installation completed successfully!")

$(print_message "$YELLOW" "Access your website: ${app_url}:3080")

============== Deployment Completed ==============

Important Information (Please Save):
- Database Host: db
- Database User: dujiaoka
- Database Password: ${mysql_pwd}
- Redis Host: redis

Note:
1. Change the admin password as soon as possible.
2. Regularly update the database password.
3. Keep the above information secure and do not disclose it.

Enjoy your application!
======================================

EOF
