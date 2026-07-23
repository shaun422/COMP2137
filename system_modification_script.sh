#!/bin/bash

#Assignment 2 - Server Configuration Script
#Name: Shaun Leonel Villaruz
#Student ID: 200635694

#Hi sir i made a few displays of which step the script is currently running so that the process can be seen while running.

cat <<EOF
========================================
 	  Configuring Server
========================================
EOF


#Checks if the script is being run as root
#Creates users, and changing the system files.
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Please run this script using sudo or switch to root access"
    exit 1
fi

cat <<EOF

----------------------------------------
 	Configuring the network
----------------------------------------
EOF
#Find the existing netplan configuration file.
#The first YAML file found will be stored in NETPLAN_FILE.

NETPLAN_FILE=$(find /etc/netplan -type f -name "*.yaml" | head -n 1)

# Check whether a netplan file was found.
if [ ! -f "$NETPLAN_FILE" ]; then
    echo "[ERROR] No netplan configuration file was found."
    exit 1
fi

echo "[INFO] Netplan file found: $NETPLAN_FILE"

#Command finds the interface currently connected to the 192.168.16 network.
SERVER_INT=$(ip -o -4 address show | grep "192.168.16." | awk '{print $2}' | head -n 1)

#Check whether the server network interface was found.
if [ -z "$SERVER_INT" ]; then
    echo "[ERROR] The 192.168.16 network interface was not found."
    exit 1
fi

echo "[INFO] Server network interface found: $SERVER_INT"

#Store the required IP address in a variable.
NEW_ADDRESS="192.168.16.21/24"

#Find the current IP address assigned to the server interface.
CURRENT_ADDRESS=$(ip -o -4 address show "$SERVER_INT" | awk '{print $4}' | head -n 1)

#Check whether the current address was found.
if [ -z "$CURRENT_ADDRESS" ]; then
    echo "[ERROR] The current IP address could is missing/cannot be found."
    exit 1
fi

echo "[INFO] Current server address: $CURRENT_ADDRESS"

#Creates a backup of the netplan file, but the backup is only created if it does not already exist.
if [ ! -f "$NETPLAN_FILE.backup" ]; then
    cp "$NETPLAN_FILE" "$NETPLAN_FILE.backup"
    echo "[INFO] A backup of the netplan file was created."
else
    echo "[INFO] The netplan backup already exists."
fi

#Changes the old server address only when needed.
#Also this command leaves the management interface unchanged.
if [ "$CURRENT_ADDRESS" != "$NEW_ADDRESS" ]; then

    if grep -q "$CURRENT_ADDRESS" "$NETPLAN_FILE"; then
        sed -i "s|$CURRENT_ADDRESS|$NEW_ADDRESS|" "$NETPLAN_FILE"
        echo "[INFO] The server address was changed to $NEW_ADDRESS."
    else
        echo "[ERROR] The current address was not found in the netplan file."
        exit 1
    fi

else
    echo "[INFO] The correct server address is already configured."
fi
