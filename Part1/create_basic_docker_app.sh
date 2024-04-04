#!/bin/bash
# filename: create_basic_docker_app.sh

# Variables gets passed from the main script.
app_name=$1
docker_username=$2

# Creates a new dotnet webapp and a gitignore file.
make_new_app(){
  # create new dotnet webapp
  dotnet new webapp -o $app_name

  # change directory to the new app
  cd $app_name

  # create new dotnet gitignore
  dotnet new gitignore
}

# Creates Dockerfile, .dockerignore and a compose. Builds and pushes the image to dockerhub.
docker_actions(){
    docker init
    docker build -t $docker_username/$app_name .
    docker push $docker_username/$app_name
}

main(){
  make_new_app
  docker_actions
}

main