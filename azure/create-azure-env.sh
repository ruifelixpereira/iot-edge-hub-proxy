#!/bin/bash

# load environment variables
set -a && source .env && set +a

# Required variables
required_vars=(
    "resourceGroupName"
    "location"
    "iotHubName"
    "iotEdgeDeviceId"
)

# Set the current directory to where the script lives.
cd "$(dirname "$0")"

# Function to check if all required arguments have been set
check_required_arguments() {
    # Array to store the names of the missing arguments
    local missing_arguments=()

    # Loop through the array of required argument names
    for arg_name in "${required_vars[@]}"; do
        # Check if the argument value is empty
        if [[ -z "${!arg_name}" ]]; then
            # Add the name of the missing argument to the array
            missing_arguments+=("${arg_name}")
        fi
    done

    # Check if any required argument is missing
    if [[ ${#missing_arguments[@]} -gt 0 ]]; then
        echo -e "\nError: Missing required arguments:"
        printf '  %s\n' "${missing_arguments[@]}"
        [ ! \( \( $# == 1 \) -a \( "$1" == "-c" \) \) ] && echo "  Either provide a .env file or all the arguments, but not both at the same time."
        [ ! \( $# == 22 \) ] && echo "  All arguments must be provided."
        echo ""
        exit 1
    fi
}

####################################################################################

# Check if all required arguments have been set
check_required_arguments

####################################################################################

#
# Create/Get a resource group.
#
rg_query=$(az group list --query "[?name=='$resourceGroupName']")
if [ "$rg_query" == "[]" ]; then
   echo -e "\nCreating Resource group '$resourceGroupName'"
   az group create --name ${resourceGroupName} --location ${location}
else
   echo "Resource group $resourceGroupName already exists."
   #RG_ID=$(az group show --name $resource_group --query id -o tsv)
fi

#
# Create IoT Hub
#
ih_query=$(az iot hub list --query "[?name=='$iotHubName']")
if [ "$ih_query" == "[]" ]; then
    echo -e "\nCreating IoT Hub '$iotHubName'"
    az iot hub create \
        --name $iotHubName \
        --resource-group $resourceGroupName \
        --sku S1
else
    echo "IoT Hub $iotHubName already exists."
fi

#
# Register Iot Edge Device
#
ed_query=$(az iot hub device-identity list --hub-name $iotHubName --edge-enabled --query "[?deviceId=='$iotEdgeDeviceId']")
if [ "$ed_query" == "[]" ]; then
    echo -e "\nRegistering IoT Edge device '$iotEdgeDeviceId'"
    az iot hub device-identity create \
        --device-id $iotEdgeDeviceId \
        --hub-name $iotHubName \
        --edge-enabled
else
    echo "IoT Edge device $iotEdgeDeviceId already registered."
fi

#
# Create a VM with IoT Edge
#

# Generate the SSH Key
ssh-keygen -m PEM -t rsa -b 4096 -q -f ~/.ssh/iotedge-vm-key -N ""

# Create a VM using the iotedge-vm-deploy script
az deployment group create \
    --resource-group $resourceGroupName \
    --template-file "main.bicep" \
    --parameters dnsLabelPrefix='my-edge-vm1076' \
    --parameters deviceConnectionString=$(az iot hub device-identity connection-string show --device-id $iotEdgeDeviceId --hub-name $iotHubName -o tsv) \
    --parameters authenticationType='sshPublicKey' \
    --parameters adminUsername='azureuser' \
    --parameters adminPasswordOrKey="$(< ~/.ssh/iotedge-vm-key.pub)"
