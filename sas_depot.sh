#!/bin/bash

# Function to read username and password
read_credentials() {
    # Read username
    echo -n "Please enter your username: "
    read username

    while true; do
        # First password entry
        echo -n "Please enter your password: "
        read -s pass1
        echo

        # Second password entry
        echo -n "Please re-enter your password: "
        read -s pass2
        echo

        # Check if passwords match
        if [ "$pass1" != "$pass2" ]; then
            echo "Passwords do not match. Please try again."
        else
            # Encode the password with hex
            hex_pass=$(echo -n "$pass1" | xxd -p)

            # Encode the hex password with Base64
            encoded_pass=$(echo -n "$hex_pass" | base64)

            # Append the username and encoded password to the file
            echo $(echo -n "$username:$encoded_pass" | xxd -p) >> sas_auth.conf

            # Inform the user
            echo "Username and password successfully encoded and saved."

            # Set file permissions
            chmod 600 sas_auth.conf

            break
        fi
    done
}

# Read credentials
read_credentials
