#!/bin/bash

# =============================================================================
# Complete Admin Summary
# =============================================================================
# Shows current status of all admin users across all services
# =============================================================================

echo "🎯 COMPLETE ADMIN SUMMARY"
echo "========================="

echo ""
echo "📮 MAILU ADMIN STATUS:"
echo "======================"
docker exec postal-db-1 mysql -u root -ppostal_root_password -e "SELECT email, enabled, global_admin, created_at FROM mailu.user;" 2>/dev/null || echo "❌ Could not query Mailu database"

echo ""
echo "📧 POSTAL ADMIN STATUS:"
echo "======================="
docker exec postal-db-1 mysql -u root -ppostal_root_password -e "SELECT email_address, admin, created_at FROM postal.users WHERE admin=1;" 2>/dev/null || echo "❌ Could not query Postal database"

echo ""
echo "📊 MAUTIC STATUS:"
echo "================="
if docker ps --format '{{.Names}}' | grep -q "mautic-web-1"; then
    echo "✅ Mautic service is running"
    echo "🌐 Setup URL: https://mautic.soham.top"
    echo "📝 Admin user must be created via web interface"
else
    echo "❌ Mautic service is not running"
fi

echo ""
echo "🔑 CURRENT WORKING CREDENTIALS:"
echo "==============================="
echo "📮 Mailu Admin:"
echo "   URL: https://mail.soham.top/admin"
echo "   Email: admin@soham.top"
echo "   Password: Grow@1234"
echo ""
echo "📧 Postal Admin:"
echo "   URL: https://postal.soham.top"
echo "   Email: admin@soham.top"
echo "   Password: Grow@1234"
echo ""
echo "📊 Mautic:"
echo "   URL: https://mautic.soham.top"
echo "   Setup: Create admin via web interface"

echo ""
echo "🔧 QUICK FIXES:"
echo "==============="
echo "• Reset Mailu password: ./setup-admin-users.sh"
echo "• Reset Postal password: ./reset-postal-password.sh"
echo "• Test all logins: ./test-login-credentials.sh"
echo "• Full deployment: ./deploy-complete-setup.sh"

echo ""
echo "🌐 SERVICE STATUS:"
echo "=================="
echo "Container status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(mailu|postal|mautic)" | head -5

echo ""
echo "✅ SETUP COMPLETE - All admin credentials should work with Grow@1234"
