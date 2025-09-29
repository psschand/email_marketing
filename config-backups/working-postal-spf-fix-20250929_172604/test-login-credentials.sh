#!/bin/bash

# =============================================================================
# Comprehensive Admin Login Test
# =============================================================================

echo "🔐 Testing admin credentials after password update..."

echo "📋 Current Database Status:"
echo "Admin user in database:"
docker exec postal-db-1 mysql -u root -ppostal_root_password -e "SELECT email, enabled, global_admin FROM mailu.user WHERE email='admin@soham.top';" 2>/dev/null

echo ""
echo "🌐 Testing Web Interface Access:"

echo "1. Testing mail.soham.top/admin accessibility..."
if curl -k --resolve mail.soham.top:443:127.0.0.1 -s https://mail.soham.top/admin/ | grep -q "Redirecting\|Mailu\|login"; then
    echo "✅ Admin interface is accessible"
else
    echo "❌ Admin interface not accessible"
fi

echo ""
echo "🔑 Manual Testing Instructions:"
echo "================================"
echo "1. Mailu Admin Panel:"
echo "   URL: https://mail.soham.top/admin"
echo "   Login: admin@soham.top / Grow@1234"
echo ""
echo "2. Postal Admin Panel:"
echo "   URL: https://postal.soham.top"
echo "   Login: admin@soham.top / Grow@1234"
echo ""
echo "3. Mautic Setup:"
echo "   URL: https://mautic.soham.top"
echo "   Follow web installer to create admin account"
echo ""
echo "🔧 If login still fails, possible reasons:"
echo "• Browser cache - clear cookies for mail.soham.top"
echo "• DNS issues - ensure DNS points to correct IP"
echo "• SSL certificate issues - check certificate validity"
echo "• Cloudflare cache - purge Cloudflare cache"
echo ""
echo "💡 Alternative passwords to try:"
echo "• Grow@1234 (should work now for both Mailu and Postal)"
echo "• admin123456 (old Mailu default)"
echo "• Check original setup logs for Postal"
echo ""
echo "🛠️ Reset passwords manually:"
echo "   Mailu:  docker exec mailu-admin-1 flask mailu password admin soham.top 'NewPassword123'"
echo "   Postal: ./reset-postal-password.sh"
