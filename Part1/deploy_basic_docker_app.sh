#!/bin/bash
# filename: deploy_basic_docker_app.sh


# Must be your dockerhub username.
# For example: docker_username="MyDockerUsername"
docker_username=""


# Variables can be changed but it is not recommended.
# You can change app_name, resource_group, and vm_name and it should still work as long as they aren't already taken.
app_name="assignment3_$(date +'%Y%m%d_%H%M%S')"
resource_group="RGassignment3_$(date +'%Y%m%d_%H%M%S')"
vm_name="assignment3_VM"
vm_port_app=80


# Create a basic new dotnet webapp
create_new_app(){
                                # $1: app_name, $2: docker_username
    ./create_basic_docker_app.sh $app_name $docker_username
}

# Creates a temporary cloud-init file, replaces the {{PLACEHOLDERS}} with the actual values for the run.
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


# Create the resource group and provision a VM.
deploy_vm(){
    az group create --location swedencentral --name $resource_group

    az vm create --name $vm_name --resource-group $resource_group \
                --image Ubuntu2204 --size Standard_B1s \
                --generate-ssh-keys \
                --custom-data @$(create_temp_cloud_init) \
                --admin-username azureuser

    az vm open-port --port $vm_port_app --resource-group $resource_group --name $vm_name --priority 150

    # show the public IP address
    publicIP=$(az vm show -d -g $resource_group -n $vm_name --query publicIps -o tsv)
    echo "Basic web application will be available at following IP in a web browser: $publicIP"
    echo "Connect to VM using: ssh azureuser@$publicIP"
}

how_to_delete_resource_group(){
    echo "When you are done with the VM, you can delete the resource group with the following command:"
    echo "az group delete --name $resource_group --yes"
}

main(){
    create_new_app
    deploy_vm
    how_to_delete_resource_group
}

main

