#!/bin/bash

# lab3.sh
# COMP2137 Assignment 3
# Shaun Leonel Villaruz - 200635694

#makes verbose mode start off as disabled
VERBOSE=""

#checks if the user entered -verbose
if [ "$1" = "-verbose" ]; then

    VERBOSE="-verbose"

fi

#this copies configure-host.sh to Server 1
if ! scp configure-host.sh remoteadmin@server1-mgmt:/root; then

    echo "There was an error copying configure-host.sh to Server 1."

    exit 1

fi

#this runs configure-host.sh on Server 1
if ! ssh remoteadmin@server1-mgmt -- /root/configure-host.sh $VERBOSE \
-name loghost \
-ip 192.168.16.3 \
-hostentry webhost 192.168.16.4; then

    echo "Error configuring Server 1."

    exit 1

fi

#this copies configure-host.sh to Server 2
if ! scp configure-host.sh remoteadmin@server2-mgmt:/root; then

    echo "An error occurred while copying configure-host.sh to Server 2."

    exit 1

fi

#this runs configure-host.sh on Server 2
if ! ssh remoteadmin@server2-mgmt -- /root/configure-host.sh $VERBOSE \
-name webhost \
-ip 192.168.16.4 \
-hostentry loghost 192.168.16.3; then

    echo "An error occurred while configuring Server 2."

    exit 1

fi

#this runs configure-host.sh on the local machine for loghost
if ! sudo ./configure-host.sh $VERBOSE \
-hostentry loghost 192.168.16.3; then

    echo "An error occurred while updating loghost on the local machine."

    exit 1

fi

#this runs configure-host.sh on the local machine for webhost
if ! sudo ./configure-host.sh $VERBOSE \
-hostentry webhost 192.168.16.4; then

    echo "An error occurred while updating webhost on the local machine."

    exit 1

fi


#displays a completion message in verbose mode
if [ "$VERBOSE" = "-verbose" ]; then

    echo "Lab 3 configuration completed."

fi
