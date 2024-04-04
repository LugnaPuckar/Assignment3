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

# Pull and run the Docker image
docker pull $docker_username/$app_name
docker run -d -p 80:8080 $docker_username/$app_name