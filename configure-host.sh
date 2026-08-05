#!/bin/bash

# -------------------------------------------------------
# configure-host.sh
# COMP2137 Assignment 3
# Shaun Leonel VIllaruz - 200635694
##!/bin/bash
# ------------------------------------------------------

#This ignors Ctrl+C, terminate, and hangup signlas
trap '' INT TERM HUP

#Makes verbose mode start off as disabled
VERBOSE=false

#Variables that store values display of the commands
NEW_HOSTNAME=""
NEW_IP""
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
