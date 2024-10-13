#!/bin/bash

# This script updates and upgrade the system packages

Header() {
	printf "\n•••••( Update and Upgrade )•••••\n"
}

# function to update the system package list
update() {
    printf "\nUpdating system packages list: \n"
    apt update -y || { echo "Failed to update packages list..."; exit 1; }
    printf "\nPackage list updated!\n\n"
}



# Backup Important Data: Always ensure that you back up important files and configurations before 
# performing a full upgrade or distribution upgrade to mitigate any risks of data loss due to changes 
# in packages.

# Mini backup function
backup() {
    sleep 1
    printf "\nBackup Important Data: Always ensure that you back up important files and configurations before performing a full upgrade or release upgrade to mitigate any risks of data loss due to changes in packages.\n\n"
    sleep 3


    read -p "Perform backup? (Y/n): " ans
    # check ans for "y" or empty string
    if [[ "${ans,,}" == "y" || -z $ans ]]
    then
        # Load backup.sh script. alternatively source /backup.sh
        . ./backup.sh
        # Call backup function
        upgrade_backup || { echo "Backup failed..."; exit 1; }
        echo "Done!"; echo
    else
        echo "Proceeding to perform $1 upgrade without backup..."; echo
        sleep 1
    fi
}


# Function to upgrade system apps
upgrade() {
    echo; echo "Performing Basic Upgrade..."; echo
    apt upgrade -y || { printf "\nUpgrade failed...\n"; exit 1; }
    echo; echo "Upgrade completed!"
}

# Function to perform full-upgrade
full_upgrade() {
    # call backup function
    backup Full

    echo; echo "Performing full upgrade..."; echo; sleep 1
    apt full-upgrade -y || { printf "\nFull Upgrade failed...\n"; exit 1; }

    sleep 1
    printf "\nFull Upgrade completed!\n\n"
}

# Function to perform release upgrade
release() {
    # call backup function
    backup Release
    
    echo "Performing Release Upgrade..."; sleep 1
    echo "Please follow the on-screen instructions for a release upgrade"
    apt do-release-upgrade -y || { printf "\nRelease Upgrade failed...\n"; exit 1; }

    sleep 1
    printf "\nRelease Upgrade completed!\n\n"
}



main() {
	Header
	sleep 1

    # Call 'update' fxn to perform package lists update   
    update
    echo
    sleep 1

read -p "Proceed to perform Upgrade? (Y/n): " xyz
if [[ ${xyz,,} == "y" || -z $xyz ]]; then
    # Display options for system upgrade to user
    PS3="Choose the type of upgrade: "

    options=(
        "Upgrade (basic)"
        "Full Upgrade (recommended)"
        "Release Upgrade"
        "Quit"
    ) # Array holding the options

    select opt in "${options[@]}"
    do
        case "$opt" in 
            "Upgrade (basic)")
                read -p "Proceed to perform Upgrade? (Y/n) " ans
                printf "\n"
                if [[ ${ans,,} == "y" || -z $ans  ]]; then
                    upgrade
                    break
                fi
                # consider a choice confirmation funtion to handle choice
                ;;

            "Full Upgrade (recommended)")
                read -p "Proceed to perform Full upgrade? (Y/n) " ans
                printf "\n"
                if [[ ${ans,,} == "y" || -z $ans  ]]; then
                    full_upgrade
                    break
                fi
                ;;

            "Release Upgrade")
                read -p "Proceed to perform Release upgrade? (Y/n) " ans
                printf "\n"
                if [[ ${ans,,} == "y" || -z $ans  ]]; then
                    release
                    break
                fi
                ;;

            "Quit")
                printf "Quitting Upgrade... \n"
                sleep 1
                break
                ;;
            *)
                printf "Please select a valid option!!\n"
        esac
    done

    sleep 1
    echo "" 

else
	echo "Skipping Upgrade..."
	sleep 1; echo
fi
}

main "$@"
