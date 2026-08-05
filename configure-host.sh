#!/bin/bash
# configure-host.sh
# COMP2137 Assignment 3
# Shaun Leonel VIllaruz - 200635694

#This ignors Ctrl+C, terminate, and hangup signlas
trap '' INT TERM HUP

#Makes verbose mode start off as disabled
VERBOSE=false

#Variables that store values display of the commands
NEW_HOSTNAME=""
NEW_IP=""
ENTRY_NAME=""
ENTRY_IP=""

#Creates a message when verbose mode is enabled
show_msg() {

    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi

}

#This will read what options/value the user enetered.
while [ $# -gt 0 ]; do

    case "$1" in

        -verbose)
            #Turns on detailed output
            VERBOSE=true
            shift
            ;;

        -name)
            #This stores the new hostname
            NEW_HOSTNAME="$2"
            shift 2
            ;;

        -ip)
            #Stores the new IP address
            NEW_IP="$2"
            shift 2
            ;;

        -hostentry)
            #Stores the hostname and IP for /etc/hosts
            ENTRY_NAME="$2"
            ENTRY_IP="$3"
            shift 3
            ;;

        *)
            #Stops if an unknown option was entered
            echo "Error: Unknown option $1" >&2
            exit 1
            ;;

    esac

done

#This if statement command will configure the hostname if -name was used

if [ -n "$NEW_HOSTNAME" ]; then

    #grabs the current hostname
    CURRENT_HOSTNAME=$(hostname)

    #checks if the hostname needs to be changed
    if [ "$CURRENT_HOSTNAME" != "$NEW_HOSTNAME" ]; then

        show_msg "Changing hostname..."

        #updates /etc/hostname
        echo "$NEW_HOSTNAME" > /etc/hostname

        #applies the new hostname immediately
        hostnamectl set-hostname "$NEW_HOSTNAME"

        #updates the hostname inside /etc/hosts
        sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts

        #this records the change in the system log
        logger "Hostname has changed from $CURRENT_HOSTNAME to $NEW_HOSTNAME"

        show_msg "Hostname updated successfully."

    else

        show_msg "Hostname is already correct."

    fi

fi

#This if statement will configure the IP address if -ip was used
if [ -n "$NEW_IP" ]; then

    #Gets the current IP address from the LAN interface
    CURRENT_IP=$(ip -4 addr show eth1 | grep inet | awk '{print $2}' | cut -d/ -f1)

    #Checks if the IP address needs to be changed
    if [ "$CURRENT_IP" != "$NEW_IP" ]; then

        show_msg "Changing IP address..."
        #Updates the IP address inside the Netplan file
        sed -i "s/$CURRENT_IP\/24/$NEW_IP\/24/g" /etc/netplan/10-lxc.yaml

        #Updates the current machine's IP inside /etc/hosts
        sed -i "s/$CURRENT_IP/$NEW_IP/g" /etc/hosts

        #Applies the new network settings
        netplan apply

        #Records the change in the system log
        logger "IP address has changed from $CURRENT_IP to $NEW_IP"

        show_msg "IP address updated successfully."
    else

        show_msg "IP address is already correct."

    fi

fi

#This if statement will add or update a host entry if -hostentry was used
if [ -n "$ENTRY_NAME" ] && [ -n "$ENTRY_IP" ]; then

    #Checks if the hostname already exists inside /etc/hosts
    if grep -q "[[:space:]]$ENTRY_NAME$" /etc/hosts; then

        #Gets the current IP connected to the hostname
        CURRENT_ENTRY_IP=$(grep "[[:space:]]$ENTRY_NAME$" /etc/hosts | awk '{print $1}')

        #Checks if the host entry has the correct IP address
        if [ "$CURRENT_ENTRY_IP" != "$ENTRY_IP" ]; then

            #Updates the old host entry with the new IP address
            sed -i "s/^$CURRENT_ENTRY_IP.*$ENTRY_NAME$/$ENTRY_IP $ENTRY_NAME/" /etc/hosts

            #Records the change in the system log
            logger "Host entry $ENTRY_NAME has changed from $CURRENT_ENTRY_IP to $ENTRY_IP"

            show_msg "Host entry for $ENTRY_NAME was updated."

        else

            show_msg "Host entry for $ENTRY_NAME is already correct."

        fi

    else

        #Adds the new hostname and IP address to /etc/hosts
        echo "$ENTRY_IP $ENTRY_NAME" >> /etc/hosts

        #Records the new host entry in the system log
        logger "Host entry $ENTRY_NAME with IP $ENTRY_IP was added"

        show_msg "Host entry for $ENTRY_NAME was added."

    fi

fi
