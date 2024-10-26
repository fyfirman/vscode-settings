#!/bin/bash

# Set error handling
set -e

# Create log directory if it doesn't exist
mkdir -p ./log

# Set log file path with current date
LOG_FILE="./log/log-$(date +'%d-%b-%Y').log"

# Function to log messages
log_message() {
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        log_message "Error: Not a git repository"
        exit 1
    fi
}

# Function to get current date and time in the required format
get_datetime() {
    date +"Update %A, %d %b %Y %H.%M"
}

# Function to cleanup old logs (keeps last 30 days)
cleanup_old_logs() {
    log_message "Checking for old log files..."
    find ./log -name "log-*.log" -type f -mtime +30 -exec rm {} \;
    log_message "Old log cleanup completed"
}

# Main script
main() {
    # Log script start
    log_message "----------------------------------------"
    log_message "Starting git auto-commit process"
    
    # Check if we're in a git repository
    check_git_repo
    
    # Check for changes
    if [[ -n $(git status -s) ]]; then
        log_message "Changes detected, proceeding with commit and push"
        
        # Log the changed files
        log_message "Changed files:"
        git status -s | while read line; do
            log_message "  $line"
        done
        
        # Add all changes
        git add .
        log_message "Added all changes to staging area"
        
        # Create commit with current date/time
        COMMIT_MESSAGE=$(get_datetime)
        git commit -m "$COMMIT_MESSAGE"
        log_message "Created commit with message: $COMMIT_MESSAGE"
        
        # Push changes
        git push
        log_message "Successfully pushed changes to remote repository"
        
    else
        log_message "No changes detected in repository"
    fi
    
    # Cleanup old logs
    cleanup_old_logs
    
    log_message "Git auto-commit process completed"
    log_message "----------------------------------------"
}

# Execute main function
main