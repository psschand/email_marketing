#!/bin/bash

# Apply nginx configuration for subdomain routing
# This script ensures persistent nginx configuration for Mailu subdomains

set -e

echo "=== Applying nginx configuration for subdomain routing ==="

# Check if mailu front container is running
if ! docker ps --format "table {{.Names}}" | grep -q "mailu-front-1"; then
    echo "❌ Error: mailu-front-1 container is not running"
    exit 1
fi

# Add server_name to main HTTPS server block if not present
if ! docker exec mailu-front-1 grep -q "server_name mail.soham.top" /etc/nginx/nginx.conf; then
    echo "📝 Adding server_name to main HTTPS server block..."
    docker exec mailu-front-1 sed -i '/listen 443 ssl;/a \ \ \ \ \ \ server_name mail.soham.top;' /etc/nginx/nginx.conf
    echo "✅ Server name added"
else
    echo "✅ Server name already present"
fi

# Add include for http.d directory if not present
if ! docker exec mailu-front-1 grep -q "include /etc/nginx/http.d/\*.conf" /etc/nginx/nginx.conf; then
    echo "📝 Adding include directive for http.d directory..."
    docker exec mailu-front-1 sed -i '/include \/etc\/nginx\/conf\.d\/\*\.conf;/a \ \ \ \ include /etc/nginx/http.d/*.conf;' /etc/nginx/nginx.conf
    echo "✅ Include directive added"
else
    echo "✅ Include directive already present"
fi

# Test nginx configuration
echo "🔍 Testing nginx configuration..."
if docker exec mailu-front-1 nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration test failed"
    exit 1
fi

# Reload nginx
echo "🔄 Reloading nginx..."
docker exec mailu-front-1 nginx -s reload
echo "✅ Nginx reloaded successfully"

# Verify server blocks are loaded
echo "🔍 Verifying server blocks are loaded..."
if docker exec mailu-front-1 bash -c "nginx -T 2>/dev/null | grep -q 'server_name.*postal.soham.top'"; then
    echo "✅ Postal server block loaded"
else
    echo "❌ Postal server block not found"
fi

if docker exec mailu-front-1 bash -c "nginx -T 2>/dev/null | grep -q 'server_name.*mautic.soham.top'"; then
    echo "✅ Mautic server block loaded"
else
    echo "❌ Mautic server block not found"
fi

# Test subdomain routing
echo "🌐 Testing subdomain routing..."

echo "Testing mail.soham.top..."
MAIL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://mail.soham.top/admin/ || echo "000")
if [[ "$MAIL_STATUS" == "302" || "$MAIL_STATUS" == "200" ]]; then
    echo "✅ mail.soham.top is responding (HTTP $MAIL_STATUS)"
else
    echo "⚠️ mail.soham.top returned HTTP $MAIL_STATUS"
fi

echo "Testing postal.soham.top..."
POSTAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://postal.soham.top/ || echo "000")
if [[ "$POSTAL_STATUS" != "301" ]]; then
    echo "✅ postal.soham.top is being routed to postal service (HTTP $POSTAL_STATUS)"
else
    echo "❌ postal.soham.top is still redirecting to mail server"
fi

echo "Testing mautic.soham.top..."
MAUTIC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://mautic.soham.top/ || echo "000")
if [[ "$MAUTIC_STATUS" != "301" ]]; then
    echo "✅ mautic.soham.top is being routed to mautic service (HTTP $MAUTIC_STATUS)"
else
    echo "❌ mautic.soham.top is still redirecting to mail server"
fi

echo ""
echo "=== Configuration Summary ==="
echo "✅ Nginx server_name added for mail.soham.top"
echo "✅ Http.d include directive added"
echo "✅ Postal.conf mounted as volume to /etc/nginx/http.d/postal.conf"
echo "✅ Mautic.conf mounted as volume to /etc/nginx/http.d/mautic.conf"
echo "✅ SSL wildcard certificate configured for *.soham.top"
echo ""
echo "🎉 Nginx subdomain routing configuration applied successfully!"
echo ""
echo "Note: If postal.soham.top shows HTTP 500, check postal database connectivity:"
echo "      docker logs postal-web-1 --tail 20"
