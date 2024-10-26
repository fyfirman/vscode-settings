#!/bin/bash

# Set error handling
set -e

# Create log directory if it doesn't exist
mkdir -p ./log

# Set log file path with current date
LOG_FILE="./log/crontab-setup-$(date +'%d-%b-%Y').log"

# Function to log messages
log_message() {
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Get absolute path of auto-commit.sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GIT_SCRIPT="$SCRIPT_DIR/auto-commit.sh"

# Check if auto-commit.sh exists
check_git_script() {
    if [ ! -f "$GIT_SCRIPT" ]; then
        log_message "Error: auto-commit.sh not found at $GIT_SCRIPT"
        exit 1
    fi
    
    if [ ! -x "$GIT_SCRIPT" ]; then
        log_message "Making auto-commit.sh executable"
        chmod +x "$GIT_SCRIPT"
    fi
}

# Display menu and get user choice
get_cron_schedule() {
    echo "Please select the schedule for git auto-commit:"
    echo "1) Every minute"
    echo "2) Every 10 minutes"
    echo "3) Every hour"
    echo "4) Every 4 hours"
    echo "5) Every 12 hours"
    echo "6) Every day at 00:00"
    echo
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1)
            CRON_SCHEDULE="* * * * *"
            SCHEDULE_DESC="every minute"
            ;;
        2)
            CRON_SCHEDULE="*/10 * * * *"
            SCHEDULE_DESC="every 10 minutes"
            ;;
        3)
            CRON_SCHEDULE="0 * * * *"
            SCHEDULE_DESC="every hour"
            ;;
        4)
            CRON_SCHEDULE="0 */4 * * *"
            SCHEDULE_DESC="every 4 hours"
            ;;
        5)
            CRON_SCHEDULE="0 */12 * * *"
            SCHEDULE_DESC="every 12 hours"
            ;;
        6)
            CRON_SCHEDULE="0 0 * * *"
            SCHEDULE_DESC="every day at 00:00"
            ;;
        *)
            log_message "Invalid choice. Exiting."
            exit 1
            ;;
    esac
    
    # Confirm selection with warning for frequent checks
    echo
    echo "You selected: $SCHEDULE_DESC"
    echo "Cron schedule will be: $CRON_SCHEDULE"
    
    # Show warning for very frequent checks
    if [[ $choice == 1 || $choice == 2 ]]; then
        echo
        echo "WARNING: You've selected a very frequent check interval."
        echo "This might create a lot of log files and system load."
    fi
    
    echo
    read -p "Is this correct? (y/n): " confirm
    if [[ $confirm != [yY] ]]; then
        log_message "Schedule selection cancelled by user"
        exit 0
    fi
}

# Check if script is already in crontab
check_existing_crontab() {
    if crontab -l 2>/dev/null | grep -q "$GIT_SCRIPT"; then
        log_message "Script already exists in crontab"
        echo "Current crontab configuration:"
        crontab -l | grep "$GIT_SCRIPT"
        echo
        read -p "Do you want to update the schedule? (y/n): " update
        if [[ $update != [yY] ]]; then
            log_message "Update cancelled by user"
            exit 0
        fi
        return 0
    fi
    return 1
}

# Setup crontab
setup_crontab() {
    log_message "Setting up crontab..."
    
    # Create temporary file
    TEMP_CRON=$(mktemp)
    
    # Save existing crontab to temporary file, removing any existing entries of our script
    crontab -l 2>/dev/null | grep -v "$GIT_SCRIPT" > "$TEMP_CRON" || echo "" > "$TEMP_CRON"
    
    # Add our script with selected schedule
    echo "$CRON_SCHEDULE $GIT_SCRIPT" >> "$TEMP_CRON"
    
    # Install new crontab
    crontab "$TEMP_CRON"
    
    # Remove temporary file
    rm "$TEMP_CRON"
    
    log_message "Crontab setup completed successfully with schedule: $SCHEDULE_DESC"
}

# Main script
main() {
    log_message "----------------------------------------"
    log_message "Starting crontab setup process"
    
    # Check if auto-commit.sh exists and is executable
    check_git_script
    
    # Check if script is already in crontab
    check_existing_crontab
    
    # Get user's preferred schedule
    get_cron_schedule
    
    # Setup crontab with selected schedule
    setup_crontab
    
    # Display current crontab for verification
    log_message "Current crontab configuration:"
    crontab -l | while read -r line; do
        log_message "  $line"
    done
    
    log_message "Crontab setup process completed"
    log_message "----------------------------------------"
    
    echo
    echo "Setup completed! The git auto-commit script will run $SCHEDULE_DESC"
    echo "You can check the logs in: $LOG_FILE"
}

# Execute main function
main