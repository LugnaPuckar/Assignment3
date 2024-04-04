#!/bin/bash
# filename: deploy_todo_docker_app.sh


# Either set the DockerHub username here or leave it empty to be prompted later.
# For example: docker_username="MyDockerUsername"
docker_username=""

# app_name --- Name of application to your DockerHub repository.
app_name="assignment3_$(date +'%Y%m%d_%H%M%S')"
resource_group="RGassignment3_$(date +'%Y%m%d_%H%M%S')"
vm_name="assignment3_VM"

# Checks if Git, Docker, and Azure CLI are installed and authenticated.
# If not, the script will exit.
checks_before_running_script() {
    check_docker_login
    check_git
    check_az_cli
    check_variable_docker_username
    check_if_docker_username_exists
}

# Checks if the user is logged in to Docker desktop application.
check_docker_login() {
    if ! docker login; then
        echo "Docker login failed. Exiting script."
        exit 1
    fi
}
# Checks if Git is installed.
check_git() {
    if ! command -v git &> /dev/null; then
        echo "Git is not installed. Please install Git and try again."
        exit 1
    fi
}
# Checks if Azure CLI is installed and authenticated.
check_az_cli() {
    if ! az account show &>/dev/null; then
        echo "Azure CLI is either not installed or not authenticated."
        exit 1
    fi
}

# Checks if docker_username is set. If not, it will prompt the user to enter it.
check_variable_docker_username(){
    if [ -z "$docker_username" ]; then
        read -p "Enter your DockerHub username: " docker_username
    fi
}

# Checks if DockerHub username exists using Docker Hub API.
check_if_docker_username_exists(){
    local url="https://hub.docker.com/v2/users/$docker_username/"
    if curl --output /dev/null --silent --head --fail "$url"; then
        echo "DockerHub username: "$docker_username"    - exists."
    else
        echo "DockerHub username: "$docker_username"    - does not exist or there was an error."
        exit 1
    fi
}

######################################################################################################

# Attempts to download the repository if it does not exist.
# Attempts to create a Dockerfile if it does not exist.
# Builds the Docker image and pushes it to DockerHub.
build_docker_todo(){
                                # $1 username, $2 appname
    ./clone_and_dockerize_todo.sh $docker_username $app_name
}

# Creates a temporary cloud-init file with the DockerHub username and application name.
# Replaces {{PLACEHOLDERS}} accordingly.
create_temp_cloud_init(){
    local temp_cloud_init=$(mktemp)
    trap 'rm -f "$temp_cloud_init"' EXIT
    cp "cloud-init_docker.sh" "$temp_cloud_init"

    sed -i '
    s/{{DOCKER_USERNAME}}/'"$docker_username"'/;
    s/{{APP_NAME}}/'"$app_name"'/;
    ' "$temp_cloud_init"
    
    echo "$temp_cloud_init"
}


# Creates the resource group and deploys a VM.
# Opens ports that are used in the compose.yaml in the cloud init.
# 80 - web application
# 8081 - MongoDB
deploy_vm(){

    az group create --location swedencentral --name $resource_group

    az vm create --name $vm_name --resource-group $resource_group \
                --image Ubuntu2204 --size Standard_B1s \
                --generate-ssh-keys \
                --custom-data @$(create_temp_cloud_init) \
                --admin-username azureuser

    open_port(){
        az vm open-port --port $1 --resource-group $resource_group --name $vm_name --priority $2
        }
    open_port 80 150
    open_port 8081 160

}

vm_public_ip(){
    publicIP=$(az vm show -d -g $resource_group -n $vm_name --query publicIps -o tsv)
    echo $publicIP
}

# Checks if docker has been installed on the VM with X $retries and $retry_delay.
verify_docker_installation_complete(){
    local retries=10
    local retry_delay=5

    echo "Downloading and installing Docker on the VM. Estimated time: <1 minute."
    for ((i=0; i<retries; i++)); do

        local version=$(ssh -o "StrictHostKeyChecking no" azureuser@$(vm_public_ip) "docker --version" 2>/dev/null)
        if [ -n "$version" ]; then
            echo "Docker is installed on the VM. Version: $version"
            return 0
        else
            echo "Docker is still being installed on the VM. Retrying in $retry_delay seconds."
            sleep $retry_delay
        fi
    done
}

# Echoes the connection information for the VM.
echo_connection_information(){
    echo "Connect to the VM:  ssh azureuser@$(vm_public_ip)"
    echo "Webapp will be available at: $(vm_public_ip)"
    echo "Mongo Express will be available at: $(vm_public_ip):8081"
}

# Menu for starting and stopping the application by sending docker compose commands to the VM.
# 1 - Start the app, 2 - Stop the app, 3 - exit to ask_to_delete_resource_group
menu_docker_compose(){
    echo "##### Application Start/Stop Menu #####"
    while true; do
        echo "(1) Start the app"
        echo "(2) Stop the app"
        echo "(3) Exit the menu"
        read -p "Enter your choice: " choice
        case $choice in
            1) echo "Starting the application - This may take a moment."; ssh -o "StrictHostKeyChecking no" azureuser@$(vm_public_ip) "sudo docker compose up -d" >/dev/null 2>&1; echo_connection_information;;
            2) echo "Stopping the application."; ssh -o "StrictHostKeyChecking no" azureuser@$(vm_public_ip) "sudo docker compose down" >/dev/null 2>&1; echo "Application is now stopped.";;
            3) echo "Exiting the menu."; ask_to_delete_resource_group;;
            *) echo "Invalid choice. Please try again.";;
        esac
    done
}

# Menu in case the user wants to delete the resource group after the script has completed.
# 1 - Yes, 2 - No, 3 - Return to menu_docker_compose
ask_to_delete_resource_group(){
    echo "##### Resource Group Deletion #####"
    echo -e "The script is now complete.\nDo you want to delete the Azure resource group to avoid unwanted costs?"
    echo "(1) Yes"
    echo "(2) No"
    echo "(3) Return to the Application Start/Stop Menu"
    read -p "Enter your choice: " choice
    case $choice in
        1) echo "Proceeding to delete the resource group"; az group delete --name $resource_group --yes;;
        2) echo "Resource group will NOT be deleted. Keep in mind that it isn't free. Exiting script."; exit 0;;
        3) menu_docker_compose;;
        *) echo "Invalid choice. Please try again.";;
    esac
}

# run the main function
main(){
    checks_before_running_script
    build_docker_todo
    deploy_vm
    verify_docker_installation_complete
    menu_docker_compose
}
main