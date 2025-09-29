#!/bin/bash

# =============================================================================
# Database Users Recreation Script - Complete Mail Server Infrastructure
# =============================================================================

set -e

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

print_status "🔧 Recreating Database Users"
print_status "============================="

# Database user configurations
declare -A DB_USERS=(
    ["mailu"]="mailu_secure_password_123"
    ["postal"]="postal_password"
    ["mautic"]="mautic_secure_password_123"
)

for user in "${!DB_USERS[@]}"; do
    password="${DB_USERS[$user]}"
    
    print_status "Recreating user: $user"
    
    # Drop user if exists and recreate
    docker exec $DB_CONTAINER mysql -u root -p$ROOT_PASSWORD -e "
        DROP USER IF EXISTS '$user'@'%';
        CREATE USER '$user'@'%' IDENTIFIED BY '$password';
        GRANT ALL PRIVILEGES ON $user.* TO '$user'@'%';
        FLUSH PRIVILEGES;
    " 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "✓ User $user created successfully"
    else
        print_error "✗ Failed to create user $user"
        exit 1
    fi
done

# Test connections
print_status "Testing database connections..."
for user in "${!DB_USERS[@]}"; do
    password="${DB_USERS[$user]}"
    
    if docker exec $DB_CONTAINER mysql -u $user -p$password -D $user -e "SELECT 'Connection successful' as status;" > /dev/null 2>&1; then
        print_success "✓ $user connection test passed"
    else
        print_error "✗ $user connection test failed"
    fi
done

print_success "🎉 Database users recreation completed!"
