
# This script handles important file backup for full system or release upgrades
# The files listed here is not comprehensive, but its the most basic
Header() {
	echo
	echo "•••••( Backup and Automate )•••••"
}

# Define backup location
BACKUP_DIR() {
    # set default valu for the Bkp_Dir
    Bkp_Dir=${1:-"$HOME/Backups"}
    if [[ -d "$Bkp_Dir" ]]; then
        printf "\nExisting Backup folder: $(realpath $Bkp_Dir)\n"
        sleep 1
    else
        mkdir -p "$Bkp_Dir"
fi 
}

# check if the rsync cimmanbis installed
check_rsync() {
    if ! command -v rsync &> /dev/null; then
        printf "\nrsync is not installed. Please install it and try again.\n\n"
        exit 1
    fi
}


# backup function for Update-n-Upgrade.sh script
upgrade_backup() {

	# check rsync
	check_rsync
	
    # Define files/directories to back up
    CONFIG_FILES=(
        "/etc/apt/sources.list"
        "/etc/hosts"
        "/etc/fstab"
        "$HOME/.bashrc"
        "$HOME/.profile"
        "$HOME/.config/"
    )

    # Define new backup dir specially for upgrades
    BACKUP_DIR
    local new="$Bkp_Dir/Upgrades/$(date +%Y-%m-%d_%H-%M-%S)"
    mkdir -p "$new"

    # Create backups
    echo "Creating backups..."  
    for FILE in "${CONFIG_FILES[@]}"; do
        
        # check if file exists
        if [ -e "$FILE" ]; then
            echo "Backing up $FILE to $new"
            
            # rsync handles backup operations better than just cp
            rsync -azsh "$FILE" "$new" || { printf "\nFailed to backup files from $FILE to $new\n"; exit 1; }
        else
            printf "\nWarning: $FILE does not exist, skipping...\n\n"
        fi
    done
    echo "Backup Ccompleted!"
}










# ====( for 'Automate Backup' task in Main.sh script )====

    # Function to perform the backup with error handling
    perform_backup() {
        local source_dir="$1"
        local dest_dir="$2"
        
        ## Create destination directory if it doesn't exist
        # mkdir -p "$dest_dir"

        # Use rsync for backup
        rsync -avzsh "$source_dir/" "$dest_dir/" || { printf "\nBackup failed...\n"; exit 1; }

        echo "Backup completed successfully from '$source_dir' to '$dest_dir'."
    }

    # Function to setup cron job
    setup_cron() {
        local source_dir="$1"
        local dest_dir="$2"

        printf "\n••••••[ Automate Backups ]••••••\n"
        sleep 1 
        echo "Configure the schedule and frequency of the Backup:"
        echo "To use the default values, just press enter!"; echo
        # Get values from user
        read -p "Minute (0-59) or [default=every minute]: " min
        read -p "Hour (0-23) or [def=every-hour]: " hr 
        read -p "Day of Month (1-31) or [def=every-week]: " day_of_mnt 
        read -p "Month (1-12) or [def=every-month]: " month 
        read -p "Day of Week (0-7, Sunday is 0 or 7) or [def=every-day]: " day_of_wk 

        # Set default values
        min=${min:-*} 
        hr=${hr:-*} 
        day_of_mnt=${day_of_mnt:-*} 
        month=${month:-*} 
        day_of_wk=${day_of_wk:-*}
        
        local schedule="$min $hr $day_of_mnt $month $day_of_wk"
        
        # Add the cron job
        (crontab -l; echo "$schedule rsync -azsh $source_dir/ $dest_dir/") | crontab - || { printf "\nFailed to set up cron job.\n"; exit 1; }
        echo "Configured Automatic Backup successfully!" 
    }
    
    # Function to interpret cron schedule
    interpret_cron() {
        local minute="$min"
        local hour="$hr"
        local day_of_month="$day_of_mnt"
        local month="$month"
        local day_of_week="$day_of_wk"
        
        # Convert numeric values to human-readable format
        local minute_text
        local hour_text
        local day_of_month_text
        local month_text
        local day_of_week_text
    
        # Interpret minute
        minute_text=$( [[ "$minute" == "*" ]] && echo " every minute" || echo "$minute" )
        
        # Interpret hour
        hour_text=$( [[ "$hour" == "*" ]] && echo "every hour" || echo "$hour" )
        
        # Interpret day of month
        day_of_month_text=$( [[ "$day_of_month" == "*" ]] && echo "Every week" || echo "$day_of_month" )
    
        # Interpret month
        case "$month" in
            1) month_text="January" ;;
            2) month_text="February" ;;
            3) month_text="March" ;;
            4) month_text="April" ;;
            5) month_text="May" ;;
            6) month_text="June" ;;
            7) month_text="July" ;;
            8) month_text="August" ;;
            9) month_text="September" ;;
            10) month_text="October" ;;
            11) month_text="November" ;;
            12) month_text="December" ;;
            *) month_text="every month" ;;
        esac
    
        # Interpret day of week
        case "$day_of_week" in
            0|7) day_of_week_text="on Sundays" ;;
            1) day_of_week_text="on Mondays" ;;
            2) day_of_week_text="on Tuesdays" ;;
            3) day_of_week_text="on Wednesdays" ;;
            4) day_of_week_text="on Thursdays" ;;
            5) day_of_week_text="on Fridays" ;;
            6) day_of_week_text="on Saturdays" ;;
            *) day_of_week_text=$( [[ -n $day_of_month_text ]] && echo '' || "of every day of the week") ;;
        esac
        
        # Construct the final interpretation
       printf "\nThis backup will automatically run: $day_of_month_text of $month_text, at $hour_text:$minute_text $day_of_week_text.\n"
    }
    

    # Main function
    Auto_bckp() {
    	# Display title
    	Header

    	# Check rsync
    	check_rsync

        # Define new backup dir specially for 'Automatic Backup' Task
        BACKUP_DIR
        local new="$Bkp_Dir/Auto_Backup/$(date +%Y-%m)"
        mkdir -p "$new"            
        
        # Prompt for the source directory
        read -p "Enter the directory you want to back up: " source_dir
        # check if the dir exists
        if [[ ! -d "$source_dir" ]]; then
            printf "Source directory does not exist. Please check the path and try again!\n\n"       
            return 1
            # usage
        fi
        echo

        # Prompt for the destination directory
        echo "Press 'enter' to use the default backup destination $new";
        read -p "Enter the destination directory for the backup: " dest_dir
        dest_dir="${dest_dir:-$new}"

        # if dest. dir dont exist...
        if [[ -n $dest_dir && ! -d "$dest_dir" ]]; then
			# create it!
        	mkdir -p "$dest_dir"
        	dest_dir=$(realpath "$dest_dir")
        fi

        # Confirm backup details
        printf "\nYou are about to back up from '$source_dir' to '$dest_dir'\n"
        read -p "Do you want to proceed? (Y/n): " confirm

        if [[ "${confirm,,}" == "y" || -z $confirm ]]; then
        
            # Perform the backup by calling the 'perform_backup' function 
            perform_backup "$source_dir" "$dest_dir"

            # Ask if user wants to set up a cron job
            echo
            read -p "Do you want to set up automatic backups for this folder? (y/N): " setup_cron_confirm

            if [[ "${setup_cron_confirm,,}" == "y" || -z $setup_cron_confirm ]]; then
                setup_cron "$source_dir" "$dest_dir"
                sleep 1                
                interpret_cron
                
            else
                echo "Automatic backup setup skipped..."
            fi

        else
            echo "Backup operation canceled."
            return 0
        fi

        printf "\nBackup operations completed!\n\n"
    }




# upgrade_backup
## This function is called from Main.sh, under 'Automate backup'
# Auto_bckp
