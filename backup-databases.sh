#!/bin/bash

# =============================================================================
# Database Backup Script - Complete Mail Server Infrastructure
# =============================================================================

set -e

BACKUP_DIR="/home/ubuntu/ms/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_CONTAINER="postal-db-1"
ROOT_PASSWORD="postal_root_password"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

print_status "Starting database backup..."

# Backup each database
databases=("mailu" "postal" "mautic")

for db in "${databases[@]}"; do
    print_status "Backing up $db database..."
    
    docker exec $DB_CONTAINER mysqldump \
        -u root -p$ROOT_PASSWORD \
        --routines --triggers \
        $db > "$BACKUP_DIR/${db}_backup_$TIMESTAMP.sql"
    
    if [ $? -eq 0 ]; then
        print_success "$db database backed up successfully"
    else
        print_error "Failed to backup $db database"
        exit 1
    fi
done

# Create compressed archive
print_status "Creating compressed backup archive..."
cd "$BACKUP_DIR"
tar -czf "mail_server_backup_$TIMESTAMP.tar.gz" *_backup_$TIMESTAMP.sql
rm -f *_backup_$TIMESTAMP.sql

print_success "Backup completed: mail_server_backup_$TIMESTAMP.tar.gz"

# Keep only last 7 backups
print_status "Cleaning old backups (keeping last 7)..."
ls -t mail_server_backup_*.tar.gz | tail -n +8 | xargs -r rm --

print_success "Backup process completed successfully!"
echo "Backup location: $BACKUP_DIR/mail_server_backup_$TIMESTAMP.tar.gz"
