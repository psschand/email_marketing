#!/bin/bash

# =============================================================================
# Complete Mail Server Infrastructure - Start All Services
# =============================================================================

set -e

echo "🚀 Starting Complete Mail Server Infrastructure..."
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

print_status "Docker is running ✓"

# Start services in order
print_status "Starting MySQL Database..."
cd postal && docker compose up -d postal-db && sleep 10
print_success "Database started"

print_status "Starting Mailu Mail Server..."
cd ../mailu && docker compose up -d
print_success "Mailu started"

print_status "Starting Postal Transactional Mail..."
cd ../postal && docker compose up -d
print_success "Postal started"

print_status "Starting Mautic Marketing Platform..."
cd .. && docker compose -f docker-compose.mautic.yml up -d
print_success "Mautic started"

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Apply nginx configurations to ensure persistence
print_status "Applying nginx configurations..."
docker exec mailu-front-1 sed -i 's/try_files $uri =404;/try_files $uri \/webmail?homepage;/' /etc/nginx/nginx.conf 2>/dev/null || true
docker exec mailu-front-1 sed -i 's/set $admin :8080;/set $admin admin:8080;/g' /etc/nginx/nginx.conf 2>/dev/null || true
docker exec mailu-front-1 grep -q "server_name mail.soham.top" /etc/nginx/nginx.conf || docker exec mailu-front-1 sed -i '/listen 443 ssl;/a \ \ server_name mail.soham.top;' /etc/nginx/nginx.conf
docker exec mailu-front-1 nginx -s reload 2>/dev/null || true
print_success "Nginx configurations applied"

# Check service status
print_status "Checking service status..."
echo ""
echo "📊 Service Status:"
echo "=================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(mailu|postal|mautic)"

echo ""
echo "🌐 Access Points:"
echo "================="
echo "• Mailu Admin:  https://mail.soham.top/"
echo "• Postal:       https://postal.soham.top/" 
echo "• Mautic:       https://mautic.soham.top/"

echo ""
echo "🔐 Login Credentials:"
echo "===================="
echo "• Mailu Admin:  admin@soham.top / Soham@1234"

echo ""
print_success "🎉 All services started successfully!"
print_status "Run './verify-project.sh' to perform health checks"
