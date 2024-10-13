#!/bin/bash

# This script handles user account security

Header() {
	printf "\n•••••( Secure User Accounts )•••••\n"
}

# Function to enforce strong password policies
enforce_password_policy() {


    # Default values
    local LEN=12
    local MAX_DAYS=90
    local MIN_DAYS=7
    local WARN_AGE=7

    # Display password policies intro
    printf "\n••••••••[ Password Policy Configuration ]••••••••\n"
    printf "Press 'Enter' to use the default values enclosed in []\n"

    # Prompt for min password length
    printf "\n1. Set Password Length\n"
    read -p "Enter minimum password length [$LEN]: " user_input
    LEN=${user_input:-$LEN}
    sleep 1

    # Prompt for password expiration policies
    printf "\n2. Configure Password Expiration Policies\n" 
    read -p "Enter Max days for which a password is valid [$MAX_DAYS]: " user_input
    MAX_DAYS=${user_input:-$MAX_DAYS}

    read -p "Enter Min days before a password can be changed [$MIN_DAYS]: " user_input
    MIN_DAYS=${user_input:-$MIN_DAYS}

    read -p "Reminder (days before password expires, [$WARN_AGE]): " user_input
    WARN_AGE=${user_input:-$WARN_AGE}
    sleep 1

    printf "\n3. Configure Password retries (P.A.M)\n"
    read -p "Enter number of password retries [4]: " PAM_RETRIES
    PAM_RETRIES=${PAM_RETRIES:-4}
    sleep 1
    

    # Display the configured values
    printf "\nConfigured Password Policies:\n"
    printf "Minimum Password Length: $LEN\n"
    printf "Maximum Password Validity Days: $MAX_DAYS\n"
    printf "Minimum Days Before Password Change: $MIN_DAYS\n"
    printf "Reminder Days Before Password Expiration: $WARN_AGE\n"
    printf "Password PAM Retries: $PAM_RETRIES\n"

    # Confirm user values before proceeding
    read -p "Proceed with these values? (Y/n): " ans
  if [[ ${ans,,} == "y" || -z $ans ]]; then

    # Backup /etc/login.defs and /etc/pam.d/common-password
    Time=$(date +%Y.%m.%d_%H:%M:%S)
    cp /etc/login.defs "/etc/login.defs.$Time"
    cp /etc/pam.d/common-password "/etc/pam.d/common-password.$Time"

    echo
    # Set minimum password length (e.g., 12 characters)
    echo "Setting minimum password length..."
    sed -i '/^PASS_MIN_LEN/c\PASS_MIN_LEN $LEN' /etc/login.defs
    sleep 1

    # Enable password expiration policies
    echo "Enabling password expiration policies..."
    sed -i '/^PASS_MAX_DAYS/c\PASS_MAX_DAYS 90' /etc/login.defs  # Max password age
    sed -i '/^PASS_MIN_DAYS/c\PASS_MIN_DAYS 7' /etc/login.defs   # Min days before change
    sed -i '/^PASS_WARN_AGE/c\PASS_WARN_AGE 7' /etc/login.defs   # Warn users 7 days before expiry
    sleep 1

    # Enforce password complexity using PAM (Pluggable Authentication Modules)
    echo "Enforcing password complexity requirements..."
    # Check if PAM has 'not' been previously configured
    if ! grep -q "pam_pwquality.so" /etc/pam.d/common-password; then
        # add this PAM config to /etc/pam.d/common-password
        echo "password requisite pam_pwquality.so retry=4 minlen=$LEN" >> /etc/pam.d/common-password      
    fi
    sleep 1
    echo "Done!"
  else
  	echo "Skipping Password Policy Confuguration..."
  	sleep 1
  fi
}


# Function to lock inactive user accounts
lock_inactive_accounts() {
    echo "Coming soon..."
    # echo "Locking inactive user accounts..."
    # # Lock accounts inactive for more than 30 days
    # useradd -D -f 30  # Set the default inactivity period for new accounts

    # # iterate through all user accounts
    # for user in $(awk -F: '{ print $1 }' /etc/passwd); do
    #     # check whether each user has a login record
    #     last_login=$(lastlog -u "$user" | awk 'NR==2 {print $4}')
    #     if [[ -z "$last_login" ]]; then
    #         # Lock account if no login record
    #         passwd -l "$user"
    #     fi
    # done
}

# Function to remove unused or default accounts
remove_unused_accounts() {
    echo "Coming soon..."
    # echo "Removing unused or default accounts..."

    # # List of known default or unused accounts
    # default_accounts=("games" "nobody" "news" "uucp" "proxy" "www-data")

    # for account in "${default_accounts[@]}"; do
    #     if id "$account" &>/dev/null; then
    #         echo "Removing account: $account"
    #         userdel "$account"
    #     fi
    # done
}

# Function to limit sudo privileges
limit_sudo_privileges() {

    echo "Limiting sudo privileges..."

    # Check for existing sudoers group (sudo or wheel)
    if getent group sudo >/dev/null; then
        EXISTING_SUDO_GROUP="sudo"
    elif getent group wheel >/dev/null; then
        EXISTING_SUDO_GROUP="wheel"
    else
        EXISTING_SUDO_GROUP=""
    fi


    # Define a new group for sudoers (if no existing group is found)
    SUDO_GROUP="admin"

    if [ -n "$EXISTING_SUDO_GROUP" ]; then
        # Display existing sudoers group
        echo "Found pre-existing sudoers group: $EXISTING_SUDO_GROUP"
    else
        # Create the sudo group if neither 'sudo' nor 'wheel' exists
        echo "No existing sudoers group found, creating a new sudoers group: $SUDO_GROUP"
        if ! getent group "$SUDO_GROUP" >/dev/null; then
            groupadd "$SUDO_GROUP"
        fi
        EXISTING_SUDO_GROUP="$SUDO_GROUP"
    fi

    # Ensure only users in the $EXISTING_SUDO_GROUP have sudo privileges
    echo "Restricting sudo privileges to only users in the $EXISTING_SUDO_GROUP group"
    echo "%$EXISTING_SUDO_GROUP ALL=(ALL) ALL" > /etc/sudoers.d/99_sudo_group

    # Remove users from sudo group if they are not part of $EXISTING_SUDO_GROUP
        # List of all users
    for user in $(getent passwd | cut -d: -f 1); do
        # List groups a user belongs to
        if groups "$user" | grep -q 'sudo'; then
            # If a user is not in the $EXISTING_SUDO_GROUP
            if ! groups "$user" | grep -q "$EXISTING_SUDO_GROUP"; then
                echo "Removing $user from sudo privileges"
                # remove the user
                gpasswd -d "$user" sudo
            fi

            # Pls add comments!!!
        elif groups "$user" | grep -q 'wheel'; then
            if ! groups "$user" | grep -q "$EXISTING_SUDO_GROUP"; then
                echo "Removing $user from wheel privileges"
                gpasswd -d "$user" wheel
            fi
        fi
    done

    echo "Sudo privileges successfully limited to the $EXISTING_SUDO_GROUP group."
}


# Main function to execute all tasks
main() {
	Header 
	
    PS3="Please select a task: "

    options=(
    "Enforce Password Policy"
    "Lock Inactive Accounts"
    "Remove Unused Accounts"
    "Limit Sudo Privileges"
    "Quit"
    )

    select opt in "${options[@]}"; do
        case $opt in
            "Enforce Password Policy")
                enforce_password_policy
				echo
                break
                ;;
            "Lock Inactive Accounts")
                lock_inactive_accounts
				echo
                ;;
            "Remove Unused Accounts")
                remove_unused_accounts
				echo
                ;;
            "Limit Sudo Privileges")
                # limit_sudo_privileges
                printf "\nComing soon...\n\n"
                ;;
            "Quit")
                echo "Quitting 'Secure User Account'..."
                sleep 1
                break
                ;;
            *)
                echo "Pls select a valid option..." 
                ;;
        esac
    done

    # echo "Secure Account tasks completed."
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Execute the main function
main
