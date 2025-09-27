#!/bin/bash

# =============================================================================
# SSL Certificate Renewal Script - Complete Mail Server Infrastructure  
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_status "🔐 SSL Certificate Renewal Process"
print_status "=================================="

# Check current certificate expiry
print_status "Checking current certificate expiry..."
if [ -f "/mailu/certs/wildcard-fullchain.pem" ]; then
    EXPIRY=$(openssl x509 -in /mailu/certs/wildcard-fullchain.pem -noout -enddate | cut -d= -f2)
    print_status "Current certificate expires: $EXPIRY"
else
    print_warning "No existing certificate found"
fi

# Check if CloudFlare credentials exist
if [ ! -f "/etc/letsencrypt/cloudflare.ini" ]; then
    print_error "CloudFlare credentials not found at /etc/letsencrypt/cloudflare.ini"
    print_status "Please ensure CloudFlare API credentials are configured"
    exit 1
fi

print_status "CloudFlare credentials found ✓"

# Renew certificate using certbot
print_status "Renewing wildcard certificate for *.soham.top..."

sudo certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
    --dns-cloudflare-propagation-seconds 60 \
    -d "*.soham.top" \
    -d "soham.top" \
    --agree-tos \
    --non-interactive \
    --force-renewal

if [ $? -eq 0 ]; then
    print_success "Certificate renewed successfully"
else
    print_error "Certificate renewal failed"
    exit 1
fi

# Copy certificates to Mailu directory
print_status "Copying certificates to Mailu directory..."

sudo cp /etc/letsencrypt/live/soham.top/fullchain.pem /mailu/certs/wildcard-fullchain.pem
sudo cp /etc/letsencrypt/live/soham.top/privkey.pem /mailu/certs/wildcard-privkey.pem
sudo cp /etc/letsencrypt/live/soham.top/cert.pem /mailu/certs/wildcard-cert.pem
sudo cp /etc/letsencrypt/live/soham.top/privkey.pem /mailu/certs/wildcard-key.pem

# Set proper permissions
sudo chown root:root /mailu/certs/wildcard-*
sudo chmod 644 /mailu/certs/wildcard-fullchain.pem /mailu/certs/wildcard-cert.pem
sudo chmod 600 /mailu/certs/wildcard-privkey.pem /mailu/certs/wildcard-key.pem

print_success "Certificates copied and permissions set"

# Reload nginx in all containers
print_status "Reloading nginx configurations..."
docker exec mailu-front-1 nginx -s reload 2>/dev/null || print_warning "Could not reload Mailu nginx"

# Verify new certificate
print_status "Verifying new certificate..."
NEW_EXPIRY=$(openssl x509 -in /mailu/certs/wildcard-fullchain.pem -noout -enddate | cut -d= -f2)
print_success "New certificate expires: $NEW_EXPIRY"

# Test HTTPS connections
print_status "Testing HTTPS connections..."
for subdomain in "mail" "postal" "mautic"; do
    if curl -s -I "https://${subdomain}.soham.top/" > /dev/null; then
        print_success "✓ https://${subdomain}.soham.top/ - OK"
    else
        print_warning "✗ https://${subdomain}.soham.top/ - Failed"
    fi
done

print_success "🎉 Certificate renewal completed successfully!"
print_status "Next automatic renewal: $(date -d '+90 days' '+%Y-%m-%d')"
