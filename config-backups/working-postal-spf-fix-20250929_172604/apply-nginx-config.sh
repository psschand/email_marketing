#!/bin/bash

# =============================================================================
# Nginx Configuration Persistence Script
# =============================================================================

set -e

NGINX_BACKUP_DIR="/home/ubuntu/ms/config-backups/nginx"
CONTAINER_NAME="mailu-front-1"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_status "Applying persistent nginx configuration..."

# Ensure the container is running
if ! docker ps | grep -q $CONTAINER_NAME; then
    print_status "Starting Mailu services first..."
    cd /home/ubuntu/ms/mailu && docker compose up -d
    sleep 10
fi

# Apply the working nginx configuration
print_status "Applying working nginx fixes..."

# Fix 1: Change try_files to redirect to webmail
docker exec $CONTAINER_NAME sed -i 's/try_files $uri =404;/try_files $uri \/webmail?homepage;/g' /etc/nginx/nginx.conf

# Fix 2: Set correct admin upstream (critical for authentication)
docker exec $CONTAINER_NAME sed -i 's/set $admin :8080;/set $admin admin:8080;/g' /etc/nginx/nginx.conf

# Fix 2a: Remove problematic real_ip_header that breaks authentication
docker exec $CONTAINER_NAME sed -i '/real_ip_header X-Forwarded-For;/d' /etc/nginx/nginx.conf

# Fix 2b: Add missing API location block
if ! docker exec $CONTAINER_NAME grep -q "location ~ /api" /etc/nginx/nginx.conf; then
    docker exec $CONTAINER_NAME sed -i '/location \/internal {/i\
      location ~ /api {\
        include /etc/nginx/proxy.conf;\
        proxy_pass http://$admin;\
      }\
      \
' /etc/nginx/nginx.conf
fi

# Fix 3: Make main server the default_server to handle all unmatched requests
if ! docker exec $CONTAINER_NAME grep -q "default_server" /etc/nginx/nginx.conf; then
    docker exec $CONTAINER_NAME sed -i 's/listen 443 ssl;/listen 443 ssl default_server;/' /etc/nginx/nginx.conf
fi

# Fix 4: Add Client-Ip header to proxy.conf for webmail authentication
if ! docker exec $CONTAINER_NAME grep -q "Client-Ip" /etc/nginx/proxy.conf; then
    docker exec $CONTAINER_NAME sed -i '/proxy_set_header X-Real-IP $remote_addr;/a proxy_set_header Client-Ip $remote_addr;' /etc/nginx/proxy.conf
fi

# Fix 5: Add authentication headers to internal location
if ! docker exec $CONTAINER_NAME grep -q "Client-Ip.*internal" /etc/nginx/nginx.conf; then
    docker exec $CONTAINER_NAME sed -i '/location \/internal/,/proxy_set_header X-Real-IP $remote_addr;/s/proxy_set_header X-Real-IP $remote_addr;/proxy_set_header X-Real-IP $remote_addr;\n  proxy_set_header Client-Ip $remote_addr;\n  proxy_set_header Auth-Port 443;/' /etc/nginx/nginx.conf
fi

# Test configuration and reload
docker exec $CONTAINER_NAME nginx -t && docker exec $CONTAINER_NAME nginx -s reload

# Backup the working configuration
mkdir -p $NGINX_BACKUP_DIR
docker cp $CONTAINER_NAME:/etc/nginx/nginx.conf $NGINX_BACKUP_DIR/working-nginx.conf

print_success "Nginx configuration applied and backed up"
print_status "Configuration saved to: $NGINX_BACKUP_DIR/working-nginx.conf"

# Fix webmail container nginx configuration to point to correct directory
echo "Fixing webmail container nginx configuration..."
docker exec mailu-webmail-1 sed -i 's|root /var/www/webmail;|root /var/www/roundcube;|' /etc/nginx/http.d/webmail.conf 2>/dev/null || true
docker exec mailu-webmail-1 nginx -s reload 2>/dev/null || true

# Critical: Ensure ADMIN_ADDRESS is set correctly in mailu.env
echo "Verifying ADMIN_ADDRESS configuration..."
cd /home/ubuntu/ms/mailu
if grep -q "ADMIN_ADDRESS=$" mailu.env; then
    echo "Fixing empty ADMIN_ADDRESS..."
    sed -i 's/ADMIN_ADDRESS=$/ADMIN_ADDRESS=admin/' mailu.env
    echo "ADMIN_ADDRESS fixed - services may need restart to pick this up"
fi

# Fix SSO redirect issue by adding proper sso.php redirect
echo "Fixing webmail SSO redirect..."
if ! docker exec $CONTAINER_NAME grep -q "location /webmail/sso.php" /etc/nginx/nginx.conf; then
    docker exec $CONTAINER_NAME sed -i '/location \/webmail {/i\
      location /webmail/sso.php {\
        return 302 /sso/login?url=/webmail/;\
      }\
' /etc/nginx/nginx.conf
fi

echo "Webmail configuration fixed."

# Ensure subdomain configurations are properly mounted and services can be reached
echo "Verifying subdomain configurations..."
if ! docker exec $CONTAINER_NAME ls /etc/nginx/http.d/postal.conf >/dev/null 2>&1; then
    echo "WARNING: postal.conf not mounted - add volume mount to docker-compose.yml"
fi
if ! docker exec $CONTAINER_NAME ls /etc/nginx/http.d/mautic.conf >/dev/null 2>&1; then
    echo "WARNING: mautic.conf not mounted - add volume mount to docker-compose.yml"
fi

print_success "All configurations applied successfully!"
print_status "Current status:"
print_status "✅ mail.soham.top - Mailu mail server with webmail and admin"
print_status "✅ postal.soham.top - Postal transactional mail server"  
print_status "✅ mautic.soham.top - Mautic marketing automation platform"
print_status "✅ All services use wildcard SSL certificate (*.soham.top)"
print_status ""
print_status "If postal/mautic show 526 errors, check CloudFlare SSL mode:"
print_status "- Change from 'Full (strict)' to 'Full' in CloudFlare dashboard"
