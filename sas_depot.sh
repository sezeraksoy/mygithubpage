#!/bin/bash

# Function to display starting message
display_starting_message() {
    sleep 1
    clear
}

# Function to prompt for user selection
select_user() {
    echo "Select the user for to enter the password:"
    PS3='Select user: '
    options=("lasradm" "rgfadmin" "sas" "sasdemo" "Exit")
    select opt in "${options[@]}"
    do
        case $opt in
            "lasradm")
                username="lasradm"
                break
                ;;
            "rgfadmin")
                username="rgfadmin"
                break
                ;;
            "sas")
                username="sas"
                break
                ;;
            "sasdemo")
                username="sasdemo"
                break
                ;;              
            "Exit")
                echo "Aborted."
                exit 0
                ;;
            *) echo "Invalid option $REPLY";;
        esac
    done
}

# Function to check if password is complex enough
is_password_complex() {
    local password="$1"
    if [[ ${#password} -ge 8 && "$password" =~ [A-Z] && "$password" =~ [a-z] && "$password" =~ [0-9] && "$password" =~ [[:punct:]] ]]; then
        return 0
    else
        return 1
    fi
}

# Function to read password and encode it
read_password() {
    while true; do
        # First password entry
        read -sp "Please enter your password: " pass1
        echo

        # Second password entry
        read -sp "Please re-enter your password: " pass2
        echo

        # Check if passwords match
        if [ "$pass1" != "$pass2" ]; then
            echo "Passwords do not match. Please try again."
        elif ! is_password_complex "$pass1"; then
            echo "Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one digit, and one special character. Please try again."
        else
            # Encode the username and password with Base64
            encoded_userandpass=$(echo -n "$username:$pass1" | base64)

            # Encode the Base64 encoded string with hex
            hex_encoded=$(echo -n "$encoded_userandpass" | xxd -p)

            # Append the hex encoded string to the file
            echo "$hex_encoded" >> sas_auth.conf

            # Inform the user
            echo "Username and password successfully encoded and saved."

            # Set file permissions
            chmod 600 sas_auth.conf

            break
        fi
    done
}

# Main script execution
display_starting_message
select_user
read_password
