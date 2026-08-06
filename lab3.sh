#!/bin/bash

# lab3.sh
# COMP2137 Assignment 3
# Shaun Leonel Villaruz - 200635694

#Makes verbose mode start off as disabled
VERBOSE=""

#Checks if the user entered -verbose
if [ "$1" = "-verbose" ]; then

    VERBOSE="-verbose"

fi

#this copies configure-host.sh to Server 1
scp configure-host.sh remoteadmin@server1-mgmt:/root

#this stops the script if copying failed
if [ $? -ne 0 ]; then

    echo "There was an Error copying configure-host.sh to Server 1."

    exit 1

fi

#this runs configure-host.sh on Server 1
ssh remoteadmin@server1-mgmt -- /root/configure-host.sh $VERBOSE \
-name loghost \
-ip 192.168.16.3 \
-hostentry webhost 192.168.16.4

#code below stops the script if Server 1 configuration failed
if [ $? -ne 0 ]; then

    echo "Error configuring Server 1."

    exit 1

fi

#this copies configure-host.sh to Server 2
scp configure-host.sh remoteadmin@server2-mgmt:/root

#stops the script if copying failed
if [ $? -ne 0 ]; then

    echo "An Error has occured while copying configure-host.sh to Server 2."

    exit 1

fi

#runs configure-host.sh on Server 2
ssh remoteadmin@server2-mgmt -- /root/configure-host.sh $VERBOSE \
-name webhost \
-ip 192.168.16.4 \
-hostentry loghost 192.168.16.3

#stops the script if Server 2 configuration failed
if [ $? -ne 0 ]; then

    echo "An Error has occured while configuring Server 2."

    exit 1

fi

#runs configure-host.sh on the local machine for loghost
sudo ./configure-host.sh $VERBOSE \
-hostentry loghost 192.168.16.3

#checks if adding loghost was successful
if [ $? -ne 0 ]; then

    echo "Error has occured while updating loghost on the local machine."

    exit 1

fi

#runs configure-host.sh on the local machine for webhost
sudo ./configure-host.sh $VERBOSE \
-hostentry webhost 192.168.16.4

#checks if adding webhost was successful
if [ $? -ne 0 ]; then

    echo "Error has occured while updating webhost on the local machine."

    exit 1

fi


#displays a completion message in verbose mode
if [ "$VERBOSE" = "-verbose" ]; then

    echo "Lab 3 configuration completed."

fi
