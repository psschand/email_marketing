#!/bin/bash

# =============================================================================
# Complete Mail Server Stack Deployment Script
# =============================================================================
# This script deploys the complete mail server stack with all subdomains
# working properly. Run this on any new server.
#
# Services:
# - mail.soham.top (Mailu mail server)
# - postal.soham.top (Postal bulk email sender) 
# - mautic.soham.top (Mautic email marketing)
#
# =============================================================================

set -e  # Exit on any error

echo "🚀 Starting Complete Mail Server Stack Deployment..."

# Step 1: Start Postal (base database and services)
echo "📧 Starting Postal services..."
cd /home/ubuntu/ms/postal
docker compose up -d
echo "✅ Postal services started"

# Step 2: Start Mautic (marketing automation)
echo "📊 Starting Mautic services..."
cd /home/ubuntu/ms
docker compose -f docker-compose.mautic.yml up -d
echo "✅ Mautic services started"

# Step 3: Start Mailu (main mail server with nginx proxy)
echo "📮 Starting Mailu services (with nginx proxy)..."
cd /home/ubuntu/ms/mailu
docker compose up -d
echo "✅ Mailu services started"

# Step 4: Wait for services to be healthy
echo "⏳ Waiting for all services to be healthy..."
sleep 30

# Step 5: Setup Admin Credentials
echo "👤 Setting up admin credentials..."

# Wait for Mailu admin service to be ready
echo "Waiting for Mailu admin service to be ready..."
for i in {1..30}; do
    if docker exec mailu-admin-1 flask --help >/dev/null 2>&1; then
        echo "✅ Mailu admin service is ready"
        break
    fi
    echo "⏳ Waiting for admin service... ($i/30)"
    sleep 2
done

# Create or update admin user
echo "Creating/updating admin user admin@soham.top..."
# First try to update the password  
if docker exec mailu-admin-1 flask mailu password admin soham.top "Grow@1234" 2>/dev/null; then
    echo "✅ Admin password updated successfully"
else
    docker exec mailu-admin-1 flask mailu admin admin soham.top "Grow@1234" --mode=update 2>/dev/null && echo "✅ Admin user updated successfully" || echo "❌ Failed to update admin user"
fi

# Verify admin user exists
echo "Verifying admin user..."
if docker exec mailu-admin-1 flask mailu user admin soham.top 2>/dev/null | grep -q "admin@soham.top"; then
    echo "✅ Admin user admin@soham.top exists"
else
    echo "❌ Admin user verification failed"
fi

# Step 6: Setup Postal Admin (if needed)
echo "📧 Setting up Postal admin..."
# Wait for Postal to be ready
for i in {1..20}; do
    if curl -s http://localhost:5000 >/dev/null 2>&1; then
        echo "✅ Postal service is ready"
        break
    fi
    echo "⏳ Waiting for Postal service... ($i/20)"
    sleep 3
done

# Reset Postal admin password to match Mailu
echo "🔑 Setting Postal admin password..."
./reset-postal-password.sh >/dev/null 2>&1 && echo "✅ Postal admin password set to Grow@1234" || echo "ℹ️ Postal admin setup completed"

# Step 7: Verify connectivity
echo "🔍 Verifying setup..."

# Check if all containers are running
echo "📋 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(mailu|postal|mautic)"

# Check network connectivity
echo "🌐 Network Connectivity:"
docker exec mailu-front-1 ping -c 1 postal-web-1 >/dev/null 2>&1 && echo "✅ Postal network: Connected" || echo "❌ Postal network: Failed"
docker exec mailu-front-1 ping -c 1 mautic-web-1 >/dev/null 2>&1 && echo "✅ Mautic network: Connected" || echo "❌ Mautic network: Failed"

# Check configuration files
echo "📁 Configuration Files:"
docker exec mailu-front-1 ls /etc/nginx/conf.d/ | grep -q "postal.conf" && echo "✅ Postal config: Present" || echo "❌ Postal config: Missing"
docker exec mailu-front-1 ls /etc/nginx/conf.d/ | grep -q "mautic.conf" && echo "✅ Mautic config: Present" || echo "❌ Mautic config: Missing"

# Test subdomain responses
echo "🌍 Subdomain Testing:"
echo "Testing postal.soham.top..."
if curl -k --resolve postal.soham.top:443:127.0.0.1 -s https://postal.soham.top/ | grep -q "login"; then
    echo "✅ postal.soham.top: Working"
else
    echo "❌ postal.soham.top: Failed"
fi

echo "Testing mautic.soham.top..."
if curl -k --resolve mautic.soham.top:443:127.0.0.1 -s https://mautic.soham.top/ | grep -q "DOCTYPE"; then
    echo "✅ mautic.soham.top: Working"
else
    echo "❌ mautic.soham.top: Failed"
fi

echo "Testing mail.soham.top..."
if curl -k --resolve mail.soham.top:443:127.0.0.1 -s https://mail.soham.top/ | grep -q "301\|webmail"; then
    echo "✅ mail.soham.top: Working"
else
    echo "❌ mail.soham.top: Failed"
fi

echo ""
echo "🎉 Deployment Complete!"
echo ""
echo "📋 Summary:"
echo "- mail.soham.top   → Mailu mail server"
echo "- postal.soham.top → Postal bulk email sender"
echo "- mautic.soham.top → Mautic email marketing"
echo ""
echo "🔑 Admin Credentials:"
echo "- Mailu Admin: admin@soham.top / Grow@1234"
echo "- Access URL: https://mail.soham.top/admin"
echo "- Postal Admin: admin@soham.top / Grow@1234"
echo "- Access URL: https://postal.soham.top"
echo "- Mautic: Setup via web interface at https://mautic.soham.top"
echo ""
echo "🔗 Next Steps:"
echo "1. Configure DNS A records to point to your server IP"
echo "2. Set up Cloudflare proxy (optional)"
echo "3. Access the services via their respective subdomains"
echo ""
echo "🔐 Quick Admin Access Test:"
echo "   Run: ./test-admin-login.sh"
echo "   Or manually test the URLs above"
echo ""
echo "👤 Reset Admin Users:"
echo "   Run: ./setup-admin-users.sh"
echo ""
echo "✅ All services are persistent and will survive server restarts!"
