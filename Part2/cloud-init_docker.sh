#!/bin/bash
# filename: cloud-init_docker.sh

# These variables get replaced by the create-temp-cloud-init function. Dont change them here.
docker_username={{DOCKER_USERNAME}}
app_name={{APP_NAME}}

# Add Docker's official GPG key
apt-get update -y
apt-get install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update -y
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Creates the compose.yaml file. Allows you to run the app on the VM with following commands:
# sudo docker compose up -d
# sudo docker compose down
    cat > /home/azureuser/compose.yaml <<EOF
services:
  # TodoApp service
  app:
    image: $docker_username/$app_name
    restart: always
    ports:
      - "80:8080"
    environment:
      - MongoDbSettings__ConnectionString=mongodb://db:27017
      - TODO_SERVICE_IMPLEMENTATION=MongoDb
      - ASPNETCORE_ENVIRONMENT=Development

  # MongoDB service
  db:
    image: mongo
    restart: always
    volumes:
      - mongodb-data:/data/db

  # Mongo Express service
  mongo-express:
    image: mongo-express
    restart: always
    ports:
      - "8081:8081"
    environment:
      - ME_CONFIG_MONGODB_SERVER=db

volumes:
  mongodb-data:
EOF
