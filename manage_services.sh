#!/bin/bash

# Path to the AdGuard Home configuration file
CONFIG_FILE="/home/ripps/AdGuardHome/AdGuardHome.yaml"

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE."
    exit 1
fi

# Function to add services
add_services() {
    echo "Adding services: $*"
    for service in "$@"; do
        # Check if the blocked_services section exists
        if grep -q "blocked_services:" "$CONFIG_FILE"; then
            # Check if the service ID is already in the list
            if ! grep -q "  - $service" "$CONFIG_FILE"; then
                # Add the service ID to the blocked_services section under ids
                sed -i "/blocked_services:/a \ \ \ \ ids:\n\ \ \ \ \ \ - $service" "$CONFIG_FILE"
                echo "Added $service to blocked_services."
            else
                echo "$service is already in blocked_services."
            fi
        else
            # If blocked_services section doesn't exist, create it with the service
            echo -e "\nfiltering:\n  blocking_ipv4: \"\"\n  blocking_ipv6: \"\"\n  blocked_services:\n    schedule:\n      time_zone: Local\n    ids:\n      - $service" >> "$CONFIG_FILE"
            echo "Created blocked_services section and added $service."
        fi
    done
}

# Function to remove services
remove_services() {
    echo "Removing services: $*"
    for service in "$@"; do
        # Check if the service is in the blocked_services section
        if grep -q "  - $service" "$CONFIG_FILE"; then
            # Remove the service from the blocked_services section
            sed -i "/  - $service/d" "$CONFIG_FILE"
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
