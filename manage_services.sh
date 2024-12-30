#!/bin/bash

# Path to the AdGuard Home configuration file
CONFIG_FILE="/home/ripps/AdGuardHome/AdGuardHome.yaml"

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed. Please install yq to proceed."
    exit 1
fi

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE."
    exit 1
fi

# Function to add services
add_services() {
    echo "Adding services: $*"
    for service in "$@"; do
        # Get current blocked services (as a list)
        current_services=$(yq e '.filtering.blocked_services.ids' "$CONFIG_FILE")

        # Check if the service is already in the list by searching the output
        if echo "$current_services" | grep -q "$service"; then
            echo "$service is already in blocked_services."
        else
            echo "$service not found, adding..."
            # Add the service to the blocked_services.ids list
            yq e '.filtering.blocked_services.ids += ["'"$service"'"]' -i "$CONFIG_FILE"
            echo "Added $service to blocked_services."
        fi
    done
}

# Function to remove services
remove_services() {
    echo "Removing services: $*"
    for service in "$@"; do
        # Get current blocked services (as a list)
        current_services=$(yq e '.filtering.blocked_services.ids' "$CONFIG_FILE")

        # Check if the service is in the list
        if echo "$current_services" | grep -q "$service"; then
            echo "$service found, removing..."
            # Remove the service from the blocked_services.ids list
            yq e 'del(.filtering.blocked_services.ids[] | select(. == "'"$service"'"))' -i "$CONFIG_FILE"
            echo "Removed $service from blocked_services."
        else
            echo "$service is not in blocked_services."
        fi
    done
}

# Check for the first argument (add/remove)
if [ "$1" == "add" ]; then
    shift
    add_services "$@"
elif [ "$1" == "remove" ]; then
    shift
    remove_services "$@"
else
    echo "Usage: $0 {add|remove} service1 service2 ..."
    exit 1
fi

# Restart the AdGuard Home service to apply the changes
sudo systemctl restart AdGuardHome

# Log the action (optional)
echo "$(date) - Performed $1 operation on services: $*" >> /var/log/adguardhome_cron.log
