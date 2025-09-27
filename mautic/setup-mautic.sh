#!/bin/bash
# =============================================================================
# Mautic Marketing Automation Setup Script
# =============================================================================
# This script sets up Mautic with proper integration to your existing mail server
#
# Usage: ./setup-mautic.sh [options]
# Options:
#   --with-proxy    Setup nginx proxy configuration
#   --domain        Set custom domain (default: mautic.soham.top)
#   --help          Show this help message
# =============================================================================

set -e

# Configuration
DOMAIN="mautic.soham.top"
WITH_PROXY=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}===============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===============================================${NC}"
}

print_step() {
    echo -e "\n${GREEN}--- $1 ---${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  Warning: $1${NC}"
}

print_error() {
    echo -e "${RED}❌ Error: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

show_usage() {
    echo "Mautic Setup Script"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --with-proxy     Setup nginx proxy configuration"
    echo "  --domain DOMAIN  Set custom domain (default: mautic.soham.top)"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0                              # Basic setup"
    echo "  $0 --with-proxy                 # Setup with nginx proxy"
    echo "  $0 --domain mautic.example.com  # Custom domain"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-proxy)
            WITH_PROXY=true
            shift
            ;;
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

check_prerequisites() {
    print_step "Checking Prerequisites"
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_success "Docker is running"
    
    # Check if postal network exists
    if ! docker network ls | grep -q postal_default; then
        print_warning "postal_default network not found. Make sure Postal is running."
        echo "Starting Postal services first..."
        cd "$PROJECT_ROOT/postal" && docker compose -f docker-compose.prod.yml up -d
        sleep 10
    fi
    print_success "Postal network available"
}

setup_directories() {
    print_step "Setting up Directory Structure"
    
    mkdir -p "$SCRIPT_DIR/config"
    mkdir -p "$SCRIPT_DIR/logs"
    mkdir -p "$SCRIPT_DIR/media"
    
    print_success "Created directories: config, logs, media"
}

setup_docker_compose() {
    print_step "Setting up Docker Compose Configuration"
    
    # Copy the main compose file to mautic directory
    if [ ! -f "$SCRIPT_DIR/docker-compose.yml" ]; then
        cp "$PROJECT_ROOT/docker-compose.mautic.yml" "$SCRIPT_DIR/docker-compose.yml"
        print_success "Copied docker-compose.yml"
        
        print_warning "Please update the <CHANGE_THIS> placeholders in docker-compose.yml"
        echo "Required updates:"
        echo "  - MAUTIC_DB_PASSWORD (use same password as Postal database)"
        echo "  - MAUTIC_SECRET_KEY (generate with: openssl rand -hex 32)"
        echo "  - Domain is already set to: $DOMAIN"
        echo
        read -p "Press Enter after updating the configuration..."
    else
        print_success "docker-compose.yml already exists"
    fi
}

setup_nginx_proxy() {
    if [ "$WITH_PROXY" = true ]; then
        print_step "Setting up Nginx Proxy Configuration"
        
        # Update domain in nginx config
        sed "s/mautic\.soham\.top/$DOMAIN/g" "$SCRIPT_DIR/nginx-mautic.conf" > "$SCRIPT_DIR/mautic.conf"
        
        # Copy to mailu directory for mounting
        cp "$SCRIPT_DIR/mautic.conf" "$PROJECT_ROOT/mailu/mautic.conf"
        
        print_success "Created nginx proxy configuration"
        print_warning "Add the following volume mount to your Mailu docker-compose.yml:"
        echo '  - "./mautic.conf:/etc/nginx/conf.d/mautic.conf:ro"'
        echo
        print_warning "Restart Mailu front container after adding the mount:"
        echo "cd $PROJECT_ROOT/mailu && docker compose restart front"
    fi
}

start_services() {
    print_step "Starting Mautic Services"
    
    cd "$SCRIPT_DIR"
    docker compose up -d
    
    print_success "Mautic services started"
    
    echo "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    if docker compose ps | grep -q "healthy\|Up"; then
        print_success "Services are running"
    else
        print_warning "Some services may not be ready yet. Check with: docker compose ps"
    fi
}

show_completion_info() {
    print_header "🎉 Mautic Setup Complete!"
    
    echo "Service Information:"
    echo "==================="
    echo "• Web Interface: http://localhost:8080"
    if [ "$WITH_PROXY" = true ]; then
        echo "• Public URL: https://$DOMAIN"
    fi
    echo "• Database: MySQL (internal)"
    echo "• Cache: Redis (internal)"
    echo "• Email: Integrated with Postal SMTP"
    echo
    
    echo "Next Steps:"
    echo "==========="
    echo "1. Visit the web interface to complete initial setup"
    echo "2. Create your admin account"
    echo "3. Configure email settings:"
    echo "   - SMTP Host: postal-smtp-1"
    echo "   - SMTP Port: 25"
    echo "   - From Email: noreply@soham.top"
    echo "4. Import your contacts and create campaigns"
    echo
    
    echo "Useful Commands:"
    echo "================"
    echo "• View logs: docker compose logs -f mautic"
    echo "• Access console: docker compose exec mautic bash"
    echo "• Stop services: docker compose down"
    echo "• Update segments: docker compose exec mautic php bin/console mautic:segments:update"
    echo
    
    if [ "$WITH_PROXY" = true ]; then
        echo "Proxy Setup:"
        echo "============"
        echo "• Add volume mount to Mailu compose file"
        echo "• Restart Mailu front: cd ../mailu && docker compose restart front"
        echo "• Configure DNS: $DOMAIN → your server IP"
        echo
    fi
    
    echo "Documentation:"
    echo "=============="
    echo "• Mautic docs: $SCRIPT_DIR/README.md"
    echo "• Project docs: $PROJECT_ROOT/README.md"
}

# Main execution
print_header "🚀 Mautic Marketing Automation Setup"

check_prerequisites
setup_directories
setup_docker_compose
setup_nginx_proxy
start_services
show_completion_info

print_success "Setup completed successfully!"
