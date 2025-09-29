#!/bin/bash

# =============================================================================
# Complete System Restart Script - Complete Mail Server Infrastructure
# =============================================================================

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

print_status "🔄 Complete System Restart"
print_status "=========================="

print_warning "This will restart all mail server services"
read -p "Continue? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Restart cancelled"
    exit 0
fi

# Stop all services
print_status "Stopping all services..."

cd /home/ubuntu/ms/mailu && docker compose down
cd /home/ubuntu/ms/postal && docker compose down
cd /home/ubuntu/ms && docker compose -f docker-compose.mautic.yml down

print_success "All services stopped"

# Wait a moment
sleep 5

# Start services using the main script
print_status "Starting all services..."
cd /home/ubuntu/ms && ./start-all-services.sh

print_success "🎉 Complete system restart finished!"
