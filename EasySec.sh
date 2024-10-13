#!/bin/bash

echo
echo "=====( Welcome to EasySec )======"
echo "by Emmanuel Edeh"; echo
echo "...System Hardening made Easy!"
echo 

### Flow: Script requires sudo priviledges, Check if  user is root.
###      Or... if user is using sudo to run script i.e $EUID == 0
### If none of the above, tell the user to run script as root or use sudo


# ===========( Root user check: )=========== #
# Function to check for root privileges
check_root_privileges() {
    if [[ "$EUID" -ne 0 ]]; then
        printf "This script must be run as root. \nUse 'sudo' or switch to root user.\n" >&2
        exit 1
    fi
}

# Make scripts executable
Script-X() {
    # Function to make scripts executable if they are not already
    for item in ./Tasks/*.sh; do
        # Confirm that item is a file
        if [[ -f "$item" ]]; then
            # If the item is 'not' executable
            if [[ ! -x "$item" ]]; then
                # Make it executable
                chmod +x "$item"
            fi
        fi
    done
}


# Main function
main() {
    check_root_privileges

    Script-X
    sleep 1

    PS3="Which task would you like to perform? "
    tasks=(
        "Update & Upgrade"
        "Secure User Account"
        "Automate Backup"
        "Firewall Setup"
        "Exit"
    )

    select opt in "${tasks[@]}"
    do
        case "$opt" in
            "Update & Upgrade")
                ./Tasks/Update-n-Upgrade.sh
                echo
                ;;
            "Secure User Account")
                ./Tasks/sec_usr.sh                
                echo
                ;;
            "Automate Backup")
            	echo
            	# source the backup script
                . ./Tasks/backup.sh
                # call Backup function
                Auto_bckp "$@"                             
                echo
                ;;
            "Firewall Setup")
                echo "Coming soon..."; echo
                ;;
            "Exit")
                echo "Exiting..."
                sleep 1; echo
                break 
                ;;
            *)
                echo "Pls enter a valid option"
                ;;
        esac
    done
}


# Call the main function
main "$@"

