#!/bin/bash
# filename: clone_and_dockerize_todo.sh

# Variables gets passed from the main script.
docker_username=$1
app_name=$2

# If the ToDoApp directory does not exist, clone the repository.
clone_app_if_not_existing(){
    if [ ! -d "ToDoApp" ]; then
        echo "Cloning the ToDoApp repository..."
        git clone https://github.com/LugnaPuckar/ToDoApp.git
    else
        echo "ToDoApp directory already exists."
    fi
}

# If Dockerfile does not exist, create a new Dockerfile.
create_dockerfile_if_not_existing(){
    if [ ! -f "Dockerfile" ]; then
        echo "Dockerfile does not exist. Creating a new Dockerfile..."
        docker init
    else
        echo "Dockerfile already exists."
    fi
}

# Build and push the Docker image to Dockerhub.
docker_build_and_push(){
    docker build -t $docker_username/$app_name .
    docker push $docker_username/$app_name
}

# Main function.
main(){
    clone_app_if_not_existing
    cd ToDoApp
    create_dockerfile_if_not_existing
    docker_build_and_push
}

main