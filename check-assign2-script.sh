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
    echo "Notice: Please run this script using sudo or switch to root access"
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
    echo "Error: No netplan configuration file was found."
    exit 1
fi

echo "Notice: Netplan file found: $NETPLAN_FILE"

#Command finds the interface currently connected to the 192.168.16 network.
SERVER_INT=$(ip -o -4 address show | grep "192.168.16." | awk '{print $2}' | head -n 1)

#Check whether the server network interface was found.
if [ -z "$SERVER_INT" ]; then
    echo "Error: The 192.168.16 network interface was not found."
    exit 1
fi

echo "Notice: Server network interface found: $SERVER_INT"

#Store the required IP address in a variable.
NEW_ADDRESS="192.168.16.21/24"

#Find the current IP address assigned to the server interface.
CURRENT_ADDRESS=$(ip -o -4 address show "$SERVER_INT" | awk '{print $4}' | head -n 1)

#Check whether the current address was found.
if [ -z "$CURRENT_ADDRESS" ]; then
    echo "Error: The current IP address could is missing/cannot be found."
    exit 1
fi

echo "Notice: Current server address: $CURRENT_ADDRESS"

#Creates a backup of the netplan file, but the backup is only created if it does not already exist.
if [ ! -f "$NETPLAN_FILE.backup" ]; then
    cp "$NETPLAN_FILE" "$NETPLAN_FILE.backup"
    echo "Notice: A backup of the netplan file was created."
else
    echo "Notice: The netplan backup already exists."
fi

#Changes the old server address only when needed.
#Also this command leaves the management interface unchanged.
if [ "$CURRENT_ADDRESS" != "$NEW_ADDRESS" ]; then

    if grep -q "$CURRENT_ADDRESS" "$NETPLAN_FILE"; then
        sed -i "s|$CURRENT_ADDRESS|$NEW_ADDRESS|" "$NETPLAN_FILE"
        echo "Notice: The server address was changed to $NEW_ADDRESS."
    else
        echo "Error: The current address was not found in the netplan file."
        exit 1
    fi

else
    echo "Notice: The correct server address is already configured."
fi

cat <<EOF

----------------------------------------
      Updating the /etc/hosts file
----------------------------------------
EOF

#Remove any old line that contains the hostname server1.
sed -i '/server1/d' /etc/hosts

#Add the correct IP address and hostname.
echo "192.168.16.21 server1" >> /etc/hosts
echo "Notice: The /etc/hosts file was updated."


#Checks the netplan file for errors before applying
echo "Notice: Checking the netplan configuration..."

netplan generate

if [ $? -ne 0 ]; then
    echo "Error: The netplan configuration has encountered an error."
    exit 1
fi

#Applies the updated network configuration
echo "Notice:  Applying the network config..."

netplan apply

if [ $? -eq 0 ]; then
    echo "Notice: The network configuration was applied."
else
    echo "Error: The network configuration could not be applied."
    exit 1
fi

cat <<EOF

----------------------------------------
      Installing required software
----------------------------------------
EOF

#Update the list of available software packages
echo "Notice: Updating the package list..."

apt update

if [ $? -ne 0 ]; then
    echo "Error: The package list could not be updated."
    exit 1
fi

#Checks whether apache2 is already installed in the system
if dpkg -s apache2 >/dev/null 2>&1; then
    echo "Notice: Apache2 is already installed."
else
    echo "Notice: Installing Apache2..."
    apt install -y apache2

    if [ $? -ne 0 ]; then
        echo "Error: Apache2 could not be installed."
        exit 1
    fi
fi

#Checks whether Squid is already installed within the system
if dpkg -s squid >/dev/null 2>&1; then
    echo "Notice: Squid is already installed."
else
    echo "Notice: Installing Squid..."
    apt install -y squid

    if [ $? -ne 0 ]; then
        echo "Error: Squid could not be installed."
        exit 1
    fi
fi

#Enables and start apache2 so it starts automatically when it boots
systemctl enable apache2
systemctl start apache2

#Checks whether Apache2 is running.
if systemctl is-active --quiet apache2; then
    echo "Notice: Apache2 is running."
else
    echo "Error: Apache2 is not running."
    exit 1
fi

#Enables and start Squid so it starts automatically at boot
systemctl enable squid
systemctl start squid

#Checks whether Squid is running

if systemctl is-active --quiet squid; then
    echo "Notice: Squid is running."
else
    echo "Error: Squid is not running."
    exit 1
fi

cat <<EOF

----------------------------------------
        Creating required users
----------------------------------------
EOF

#Storing all required usernames in one variable
USERS="dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda"

#A loop to go through each username one at a time.
for USERNAME in $USERS; do
    echo
    echo "Notice: Checking user: $USERNAME"
    id "$USERNAME" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        useradd -m -d "/home/$USERNAME" -s /bin/bash "$USERNAME"
        echo "Notice: User $USERNAME was created."
    else
        echo "Notice: User $USERNAME already exists."
        usermod -d "/home/$USERNAME" -s /bin/bash "$USERNAME"
    fi
#Stores the location of the user's .ssh directory
    SSH_DIR="/home/$USERNAME/.ssh"

#Checks if the .ssh directory already exists
    if [ ! -d "$SSH_DIR" ]; then
        mkdir "$SSH_DIR"
        echo "Notice: .ssh directory created for $USERNAME."
    else
        echo "Notice: .ssh directory already exists."
    fi

#Creates an RSA key if one does not already exist
    if [ ! -f "$SSH_DIR/id_rsa" ]; then
        ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/id_rsa" -N ""
        echo "Notice: RSA key created."
    else
        echo "Notice: RSA key already exists."
    fi
#Creates a ED25519 key if one does not already exist
    if [ ! -f "$SSH_DIR/id_ed25519" ]; then
        ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -N ""
        echo "Notice: ED25519 key created."
    else
        echo "Notice: ED25519 key already exists."
    fi
#Stores the authorized_keys file location.
    AUTH_KEYS="$SSH_DIR/authorized_keys"

    #Creates the authorized_keys file if it does not exist
    if [ ! -f "$AUTH_KEYS" ]; then
        touch "$AUTH_KEYS"
        echo "Notice: authorized_keys file created."
    else
        echo "Notice: authorized_keys file already exists."
    fi
#Stores both generated public keys in variables.

    RSA_KEY=$(cat "$SSH_DIR/id_rsa.pub")
    ED_KEY=$(cat "$SSH_DIR/id_ed25519.pub")
#Adds the RSA public key only if it is not already present
    if grep -qF "$RSA_KEY" "$AUTH_KEYS"; then
        echo "Notice: RSA public key is already authorized."
    else
        echo "$RSA_KEY" >> "$AUTH_KEYS"
        echo "Notice: RSA public key added to authorized_keys."
    fi

#Adds the ED25519 public key only if it is not already present

    if grep -qF "$ED_KEY" "$AUTH_KEYS"; then
        echo "Notice: ED25519 public key is already authorized."
    else
        echo "$ED_KEY" >> "$AUTH_KEYS"
        echo "Notice: ED25519 public key added to authorized_keys."
    fi
    if [ "$USERNAME" = "dennis" ]; then

        # Add Dennis to the sudo group if needed.
        if id -nG dennis | grep -qw sudo; then
            echo "Notice: Dennis is already in the sudo group."
        else
            usermod -aG sudo dennis
            echo "Notice: Dennis was added to the sudo group."
        fi
        #The public key for Dennis
        DENNIS_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

        #Adds the extra key only if it is not already present.
        if grep -qF "$DENNIS_KEY" "$AUTH_KEYS"; then
            echo "Notice: Dennis's extra SSH key is already authorized."
        else
            echo "$DENNIS_KEY" >> "$AUTH_KEYS"
            echo "Notice: Dennis's extra SSH key was added."
        fi

    fi
    #Sets the correct owner for the user's SSH files
    chown -R "$USERNAME:$USERNAME" "$SSH_DIR"

    #Sets secure permissions on the .ssh directory and the authorized_keys file
    chmod 700 "$SSH_DIR"
    chmod 600 "$AUTH_KEYS"

    #Set permissions for the private and public keys
    chmod 600 "$SSH_DIR/id_rsa"
    chmod 644 "$SSH_DIR/id_rsa.pub"
    chmod 600 "$SSH_DIR/id_ed25519"
    chmod 644 "$SSH_DIR/id_ed25519.pub"

    echo "Notice: Ownership and permissions were set for $USERNAME."

done
