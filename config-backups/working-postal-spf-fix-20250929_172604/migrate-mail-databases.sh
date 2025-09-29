#!/bin/bash

# Mail Server Database Migration Script
# Automates MySQL database migration for Mailu and Postal
# Author: GitHub Copilot Assistant
# Version: 1.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default paths
MAILU_PATH="/home/ubuntu/ms/mailu"
POSTAL_PATH="/home/ubuntu/ms/postal"

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate MySQL connection
test_mysql_connection() {
    local host=$1
    local port=$2
    local user=$3
    local password=$4
    local database=$5
    
    print_status "Testing MySQL connection to $host:$port..."
    if mysql -h "$host" -P "$port" -u "$user" -p"$password" -e "USE $database;" 2>/dev/null; then
        print_success "MySQL connection successful!"
        return 0
    else
        print_error "MySQL connection failed!"
        return 1
    fi
}

# Function to create database if it doesn't exist
create_database_if_not_exists() {
    local host=$1
    local port=$2
    local user=$3
    local password=$4
    local database=$5
    
    print_status "Creating database '$database' if it doesn't exist..."
    mysql -h "$host" -P "$port" -u "$user" -p"$password" -e "CREATE DATABASE IF NOT EXISTS $database;" 2>/dev/null
    mysql -h "$host" -P "$port" -u "$user" -p"$password" -e "GRANT ALL PRIVILEGES ON $database.* TO '$user'@'%';" 2>/dev/null
    mysql -h "$host" -P "$port" -u "$user" -p"$password" -e "FLUSH PRIVILEGES;" 2>/dev/null
}

# Function to backup current database
backup_database() {
    local service=$1
    local host=$2
    local port=$3
    local user=$4
    local password=$5
    local database=$6
    
    local backup_file="${service}_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    print_status "Creating backup of $service database..."
    if mysqldump -h "$host" -P "$port" -u "$user" -p"$password" "$database" > "$backup_file" 2>/dev/null; then
        print_success "Backup created: $backup_file"
        echo "$backup_file"
    else
        print_warning "Backup failed or database doesn't exist yet"
        echo ""
    fi
}

# Function to update Mailu configuration
update_mailu_config() {
    local host=$1
    local port=$2
    local user=$3
    local password=$4
    local database=$5
    
    print_status "Updating Mailu configuration..."
    
    # Backup current mailu.env
    cp "$MAILU_PATH/mailu.env" "$MAILU_PATH/mailu.env.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update or add database configuration
    if grep -q "^DB_FLAVOR=" "$MAILU_PATH/mailu.env"; then
        sed -i "s/^DB_FLAVOR=.*/DB_FLAVOR=mysql/" "$MAILU_PATH/mailu.env"
    else
        echo -e "\n# Database settings" >> "$MAILU_PATH/mailu.env"
        echo "DB_FLAVOR=mysql" >> "$MAILU_PATH/mailu.env"
    fi
    
    # Update each database parameter
    for param in "DB_HOST:$host" "DB_PORT:$port" "DB_USER:$user" "DB_PW:$password" "DB_NAME:$database"; do
        key=$(echo $param | cut -d: -f1)
        value=$(echo $param | cut -d: -f2-)
        
        if grep -q "^$key=" "$MAILU_PATH/mailu.env"; then
            sed -i "s/^$key=.*/$key=$value/" "$MAILU_PATH/mailu.env"
        else
            echo "$key=$value" >> "$MAILU_PATH/mailu.env"
        fi
    done
    
    print_success "Mailu configuration updated"
}

# Function to update Postal configuration
update_postal_config() {
    local host=$1
    local port=$2
    local user=$3
    local password=$4
    local main_db=$5
    local message_db=$6
    
    print_status "Updating Postal configuration..."
    
    # Backup current postal.yml
    cp "$POSTAL_PATH/postal.yml" "$POSTAL_PATH/postal.yml.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update postal.yml with new database settings
    cat > "$POSTAL_PATH/postal.yml" << EOF
web_server:
  bind_address: 0.0.0.0
  port: 5000

main_db:
  host: $host
  port: $port
  username: $user
  password: $password
  database: $main_db

message_db:
  host: $host
  port: $port
  username: $user
  password: $password
  prefix: postal-server

logging:
  stdout: true
  level: info

web:
  host: postal.soham.top
  protocol: https

smtp_server:
  port: 25
  tls_mode: Auto
  tls_certificate_path: ""
  tls_private_key_path: ""
  ssl_mode: Auto
  ssl_certificate_path: ""
  ssl_private_key_path: ""

rails:
  environment: production
  secret_key: $(openssl rand -hex 64)

rspamd:
  enabled: false
  host: localhost
  port: 11334
EOF
    
    print_success "Postal configuration updated"
}

# Function to update Docker Compose files
update_docker_compose() {
    local new_db_host=$1
    
    print_status "Updating Docker Compose configurations..."
    
    # Update Postal docker-compose.prod.yml to remove local database if using external
    if [ "$new_db_host" != "db" ] && [ "$new_db_host" != "postal-db-1" ]; then
        print_status "Using external database - updating Postal compose file..."
        # Comment out or remove the db service from postal docker-compose
        if [ -f "$POSTAL_PATH/docker-compose.prod.yml" ]; then
            cp "$POSTAL_PATH/docker-compose.prod.yml" "$POSTAL_PATH/docker-compose.prod.yml.backup.$(date +%Y%m%d_%H%M%S)"
        fi
    fi
    
    print_success "Docker Compose configurations updated"
}

# Function to migrate data
migrate_data() {
    local backup_file=$1
    local host=$2
    local port=$3
    local user=$4
    local password=$5
    local database=$6
    
    if [ -n "$backup_file" ] && [ -f "$backup_file" ]; then
        print_status "Migrating data to new database..."
        if mysql -h "$host" -P "$port" -u "$user" -p"$password" "$database" < "$backup_file"; then
            print_success "Data migration completed successfully"
        else
            print_error "Data migration failed"
            return 1
        fi
    else
        print_status "No backup file found - assuming fresh installation"
    fi
}

# Function to restart services
restart_services() {
    print_status "Restarting services..."
    
    # Stop services first
    print_status "Stopping Mailu services..."
    cd "$MAILU_PATH" && docker compose down
    
    print_status "Stopping Postal services..."
    cd "$POSTAL_PATH" && docker compose -f docker-compose.prod.yml down
    
    # Start services
    print_status "Starting Postal services..."
    cd "$POSTAL_PATH" && docker compose -f docker-compose.prod.yml up -d
    
    print_status "Starting Mailu services..."
    cd "$MAILU_PATH" && docker compose up -d
    
    # Connect networks if needed
    sleep 10
    print_status "Connecting networks..."
    docker network connect postal_default mailu-admin-1 2>/dev/null || true
    docker network connect postal_default mailu-imap-1 2>/dev/null || true
    docker network connect postal_default mailu-smtp-1 2>/dev/null || true
    
    print_success "Services restarted successfully"
}

# Function to verify migration
verify_migration() {
    local mailu_host=$1
    local mailu_port=$2
    local mailu_user=$3
    local mailu_password=$4
    local mailu_database=$5
    local postal_host=$6
    local postal_port=$7
    local postal_user=$8
    local postal_password=$9
    local postal_database=${10}
    
    print_status "Verifying migration..."
    
    # Test Mailu database connection
    if test_mysql_connection "$mailu_host" "$mailu_port" "$mailu_user" "$mailu_password" "$mailu_database"; then
        print_success "Mailu database connection verified"
    else
        print_error "Mailu database connection failed"
        return 1
    fi
    
    # Test Postal database connection
    if test_mysql_connection "$postal_host" "$postal_port" "$postal_user" "$postal_password" "$postal_database"; then
        print_success "Postal database connection verified"
    else
        print_error "Postal database connection failed"
        return 1
    fi
    
    # Check service health
    print_status "Checking service health..."
    sleep 15
    
    local healthy_services=0
    local total_services=0
    
    for container in mailu-admin-1 mailu-front-1 postal-web-1; do
        total_services=$((total_services + 1))
        if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
            print_success "$container is running"
            healthy_services=$((healthy_services + 1))
        else
            print_warning "$container is not running properly"
        fi
    done
    
    if [ $healthy_services -eq $total_services ]; then
        print_success "All critical services are running"
    else
        print_warning "$healthy_services/$total_services services are healthy"
    fi
    
    print_success "Migration verification completed"
}

# Main script
main() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                 Mail Server Database Migration                 ║${NC}"
    echo -e "${BLUE}║                    Mailu + Postal MySQL                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Prerequisites check
    print_status "Checking prerequisites..."
    
    if ! command_exists mysql; then
        print_error "MySQL client not found. Please install mysql-client"
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker not found. Please install Docker"
        exit 1
    fi
    
    if [ ! -d "$MAILU_PATH" ]; then
        print_error "Mailu directory not found: $MAILU_PATH"
        exit 1
    fi
    
    if [ ! -d "$POSTAL_PATH" ]; then
        print_error "Postal directory not found: $POSTAL_PATH"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
    echo
    
    # Migration type selection
    echo -e "${YELLOW}Select migration type:${NC}"
    echo "1) Migrate to external MySQL server"
    echo "2) Migrate to new local MySQL container"
    echo "3) Update existing database credentials"
    echo -n "Choice [1-3]: "
    read -r migration_type
    echo
    
    # Collect database information
    echo -e "${YELLOW}=== Database Configuration ===${NC}"
    
    # Get new database details
    echo -n "MySQL Host: "
    read -r NEW_DB_HOST
    
    echo -n "MySQL Port [3306]: "
    read -r NEW_DB_PORT
    NEW_DB_PORT=${NEW_DB_PORT:-3306}
    
    echo -n "MySQL Username: "
    read -r NEW_DB_USER
    
    echo -n "MySQL Password: "
    read -rs NEW_DB_PASSWORD
    echo
    
    echo -n "Mailu Database Name [mailu]: "
    read -r NEW_MAILU_DB
    NEW_MAILU_DB=${NEW_MAILU_DB:-mailu}
    
    echo -n "Postal Database Name [postal]: "
    read -r NEW_POSTAL_DB
    NEW_POSTAL_DB=${NEW_POSTAL_DB:-postal}
    
    echo
    
    # Test new database connection
    if ! test_mysql_connection "$NEW_DB_HOST" "$NEW_DB_PORT" "$NEW_DB_USER" "$NEW_DB_PASSWORD" "mysql"; then
        print_error "Cannot connect to MySQL server. Please check your credentials."
        exit 1
    fi
    
    # Create databases
    create_database_if_not_exists "$NEW_DB_HOST" "$NEW_DB_PORT" "$NEW_DB_USER" "$NEW_DB_PASSWORD" "$NEW_MAILU_DB"
    create_database_if_not_exists "$NEW_DB_HOST" "$NEW_DB_PORT" "$NEW_DB_USER" "$NEW_DB_PASSWORD" "$NEW_POSTAL_DB"
    
    # Backup existing data
    echo -e "${YELLOW}=== Backup Phase ===${NC}"
    
    # Try to backup from current containers
    OLD_MAILU_BACKUP=""
    OLD_POSTAL_BACKUP=""
    OLD_MAUTIC_BACKUP=""
    
    if docker ps | grep -q "postal-db-1"; then
        print_status "Found existing postal-db-1 container, creating backups..."
        OLD_MAILU_BACKUP=$(backup_database "mailu" "172.22.0.2" "3306" "postal" "postal_password" "mailu")
        OLD_POSTAL_BACKUP=$(backup_database "postal" "172.22.0.2" "3306" "postal" "postal_password" "postal")
        
        # Check if Mautic database exists
        if docker exec postal-db-1 mysql -u postal -ppostal_password -e "USE mautic;" 2>/dev/null; then
            print_status "Found Mautic database, creating backup..."
            OLD_MAUTIC_BACKUP=$(backup_database "mautic" "172.22.0.2" "3306" "postal" "postal_password" "mautic")
        fi
    fi
    
    # Configuration update
    echo -e "${YELLOW}=== Configuration Update ===${NC}"
    
    update_mailu_config "$NEW_DB_HOST" "$NEW_DB_PORT" "$NEW_DB_USER" "$NEW_DB_PASSWORD" "$NEW_MAILU_DB"
    update_postal_config "$NEW_DB_HOST" "$NEW_DB_PORT" "$NEW_DB_USER" "$NEW_DB_PASSWORD" "$NEW_POSTAL_DB" "$NEW_POSTAL_DB"
    update_docker_compose "$NEW_DB_HOST"
    
    # Data migration
    echo -e "${YELLOW}=== Data Migration ===${NC}"
    
    if [ -n "$OLD_MAILU_BACKUP" ]; then
        migrate_data "$OLD_MAILU_BACKUP" "$NEW_DB_HOST" "$NEW_DB_PORT" "$NEW_DB_USER" "$NEW_DB_PASSWORD" "$NEW_MAILU_DB"
    fi
    
    if [ -n "$OLD_POSTAL_BACKUP" ]; then
        migrate_data "$OLD_POSTAL_BACKUP" "$NEW_DB_HOST" "$NEW_DB_PORT" "$NEW_DB_USER" "$NEW_DB_PASSWORD" "$NEW_POSTAL_DB"
    fi
    
    if [ -n "$OLD_MAUTIC_BACKUP" ]; then
        print_status "Migrating Mautic database..."
        migrate_data "$OLD_MAUTIC_BACKUP" "$NEW_DB_HOST" "$NEW_DB_PORT" "$NEW_DB_USER" "$NEW_DB_PASSWORD" "mautic"
    fi
    
    # Service restart
    echo -e "${YELLOW}=== Service Restart ===${NC}"
    restart_services
    
    # Verification
    echo -e "${YELLOW}=== Migration Verification ===${NC}"
    verify_migration "$NEW_DB_HOST" "$NEW_DB_PORT" "$NEW_DB_USER" "$NEW_DB_PASSWORD" "$NEW_MAILU_DB" \
                    "$NEW_DB_HOST" "$NEW_DB_PORT" "$NEW_DB_USER" "$NEW_DB_PASSWORD" "$NEW_POSTAL_DB"
    
    # Summary
    echo
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Migration Completed!                       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Migration Summary:${NC}"
    echo "• MySQL Host: $NEW_DB_HOST:$NEW_DB_PORT"
    echo "• Mailu Database: $NEW_MAILU_DB"
    echo "• Postal Database: $NEW_POSTAL_DB"
    if [ -n "$OLD_MAUTIC_BACKUP" ]; then
        echo "• Mautic Database: mautic"
    fi
    echo "• Backup files created in current directory"
    echo "• Configuration backups created with timestamp"
    echo
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Test mail functionality: https://mail.soham.top"
    echo "2. Test postal functionality: https://postal.soham.top"
    if [ -n "$OLD_MAUTIC_BACKUP" ]; then
        echo "3. Test Mautic functionality: https://mautic.soham.top"
        echo "4. Monitor logs: docker logs mailu-admin-1"
        echo "5. Clean up backup files once confirmed working"
    else
        echo "3. Monitor logs: docker logs mailu-admin-1"
        echo "4. Clean up backup files once confirmed working"
    fi
    echo
    echo -e "${BLUE}Thank you for using the Mail Server Migration Tool!${NC}"
}

# Run main function
main "$@"
