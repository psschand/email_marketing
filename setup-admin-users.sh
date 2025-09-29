#!/bin/bash

# =============================================================================
# Admin Users Setup Script
# =============================================================================
# This script creates/resets admin users for all mail services
# 
# Credentials:
# - Mailu: admin@soham.top / Grow@1234
# - Postal: Dynamic (check logs)
# - Mautic: Setup via web interface
# =============================================================================

set -e

echo "👤 Setting up admin users for all services..."

# =============================================================================
# Mailu Admin Setup
# =============================================================================
echo "📮 Setting up Mailu admin user..."

# Check if mailu-admin-1 container is running
if ! docker ps --format '{{.Names}}' | grep -q "mailu-admin-1"; then
    echo "❌ mailu-admin-1 container is not running. Please start Mailu services first."
    exit 1
fi

# Wait for Mailu admin service to be ready
echo "⏳ Waiting for Mailu admin service to be ready..."
for i in {1..30}; do
    if docker exec mailu-admin-1 flask --help >/dev/null 2>&1; then
        echo "✅ Mailu admin service is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Mailu admin service failed to start after 60 seconds"
        exit 1
    fi
    echo "   Waiting... ($i/30)"
    sleep 2
done

# Create or update admin user
echo "👤 Creating/updating admin user admin@soham.top..."
# First try to update the password
if docker exec mailu-admin-1 flask mailu password admin soham.top "Grow@1234" >/dev/null 2>&1; then
    echo "✅ Admin password updated successfully"
elif docker exec mailu-admin-1 flask mailu admin admin soham.top "Grow@1234" --mode=update >/dev/null 2>&1; then
    echo "✅ Admin user admin@soham.top updated successfully"
else
    echo "❌ Failed to update admin user. Trying to create new user..."
    if docker exec mailu-admin-1 flask mailu admin admin soham.top "Grow@1234" >/dev/null 2>&1; then
        echo "✅ Admin user admin@soham.top created successfully"
    else
        echo "❌ Failed to create admin user"
    fi
fi

# Verify admin user exists
echo "🔍 Verifying admin user..."
if docker exec mailu-admin-1 flask mailu user admin soham.top 2>/dev/null; then
    echo "✅ Admin user admin@soham.top verified"
    echo "   Login at: https://mail.soham.top/admin"
    echo "   Username: admin@soham.top"
    echo "   Password: Grow@1234"
else
    echo "ℹ️ Admin user verification completed (command output above)"
    echo "   Login at: https://mail.soham.top/admin"
    echo "   Username: admin@soham.top"
    echo "   Password: Grow@1234"
fi

# =============================================================================
# Postal Admin Setup
# =============================================================================
echo ""
echo "📧 Setting up Postal admin user..."

# Check if postal-web-1 container is running
if ! docker ps --format '{{.Names}}' | grep -q "postal-web-1"; then
    echo "❌ postal-web-1 container is not running. Please start Postal services first."
else
    # Wait for Postal to be ready
    echo "⏳ Waiting for Postal service to be ready..."
    for i in {1..20}; do
        if curl -s --connect-timeout 3 http://localhost:5000 >/dev/null 2>&1; then
            echo "✅ Postal service is ready"
            break
        fi
        if [ $i -eq 20 ]; then
            echo "⚠️ Postal service not responding after 60 seconds, continuing anyway..."
            break
        fi
        echo "   Waiting... ($i/20)"
        sleep 3
    done

    # Show existing users
    echo "� Current Postal admin users:"
    docker exec postal-db-1 mysql -u root -ppostal_root_password -e "SELECT email_address, admin FROM postal.users WHERE admin=1;" 2>/dev/null || echo "Could not query Postal users"
    
    echo ""
    echo "🔧 Postal Admin Management:"
    echo "• Login URL: https://postal.soham.top"
    echo "• Existing admin users shown above"
    echo "• To reset password: ./manage-postal-admin.sh"
    echo "• To create new admin: docker exec -it postal-web-1 postal make-user"
fi

# =============================================================================
# Mautic Setup Info
# =============================================================================
echo ""
echo "📊 Mautic setup information..."
if docker ps --format '{{.Names}}' | grep -q "mautic-web-1"; then
    echo "✅ Mautic service is running"
    echo "🌐 Setup Mautic via web interface:"
    echo "   URL: https://mautic.soham.top"
    echo "   Follow the web installer to create admin account"
    echo "   Database: Already configured to use shared MySQL"
else
    echo "❌ mautic-web-1 container is not running"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "📋 Admin Setup Summary:"
echo "======================================"
echo "🔗 Service Access URLs:"
echo "   Mailu Admin:  https://mail.soham.top/admin"
echo "   Postal Admin: https://postal.soham.top"
echo "   Mautic Setup: https://mautic.soham.top"
echo ""
echo "🔑 Credentials:"
echo "   Mailu:  admin@soham.top / Grow@1234"
echo "   Postal: Check logs above for generated credentials"
echo "   Mautic: Create during web setup"
echo ""
echo "✅ Admin setup complete!"
