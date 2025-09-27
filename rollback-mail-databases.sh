#!/bin/bash

# Mail Server Database Rollback Script
# Companion to migrate-mail-databases.sh
# Author: GitHub Copilot Assistant
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default paths
MAILU_PATH="/home/ubuntu/ms/mailu"
POSTAL_PATH="/home/ubuntu/ms/postal"

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to list available backups
list_backups() {
    local path=$1
    local type=$2
    
    echo -e "${YELLOW}Available $type backups:${NC}"
    ls -la "$path"/*.backup.* 2>/dev/null | nl || echo "No backups found"
}

# Function to restore configuration
restore_config() {
    local service=$1
    local backup_file=$2
    local target_file=$3
    
    if [ -f "$backup_file" ]; then
        print_status "Restoring $service configuration..."
        cp "$backup_file" "$target_file"
        print_success "$service configuration restored"
    else
        print_error "Backup file not found: $backup_file"
        return 1
    fi
}

# Main rollback function
main() {
    clear
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                 Mail Server Database Rollback                 ║${NC}"
    echo -e "${RED}║                      Configuration Recovery                   ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    print_warning "This will restore previous configurations and restart services."
    echo -n "Are you sure you want to continue? [y/N]: "
    read -r confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_status "Rollback cancelled"
        exit 0
    fi
    
    echo
    echo -e "${YELLOW}=== Available Backups ===${NC}"
    
    # List Mailu backups
    list_backups "$MAILU_PATH" "Mailu"
    echo
    
    # List Postal backups  
    list_backups "$POSTAL_PATH" "Postal"
    echo
    
    # Select Mailu backup
    echo -n "Enter Mailu backup filename (or 'skip'): "
    read -r mailu_backup
    
    if [ "$mailu_backup" != "skip" ] && [ -f "$MAILU_PATH/$mailu_backup" ]; then
        restore_config "Mailu" "$MAILU_PATH/$mailu_backup" "$MAILU_PATH/mailu.env"
    fi
    
    # Select Postal backup
    echo -n "Enter Postal backup filename (or 'skip'): "
    read -r postal_backup
    
    if [ "$postal_backup" != "skip" ] && [ -f "$POSTAL_PATH/$postal_backup" ]; then
        restore_config "Postal" "$POSTAL_PATH/$postal_backup" "$POSTAL_PATH/postal.yml"
    fi
    
    # Restart services
    print_status "Restarting services with restored configurations..."
    
    cd "$MAILU_PATH" && docker compose down
    cd "$POSTAL_PATH" && docker compose -f docker-compose.prod.yml down
    
    cd "$POSTAL_PATH" && docker compose -f docker-compose.prod.yml up -d
    cd "$MAILU_PATH" && docker compose up -d
    
    print_success "Rollback completed! Please verify your services."
}

main "$@"
