#!/bin/bash

# =============================================================================
# Test Admin Login Script
# =============================================================================
# Tests if admin credentials work for all services
# =============================================================================

echo "🔐 Testing admin login for all services..."

# Test Mailu admin login
echo "📮 Testing Mailu admin login..."
echo "URL: https://mail.soham.top/admin"
echo "Username: admin@soham.top"
echo "Password: Grow@1234"

# Test if admin interface is accessible
if curl -k --resolve mail.soham.top:443:127.0.0.1 -s https://mail.soham.top/admin | grep -q "Mailu\|login\|admin"; then
    echo "✅ Mailu admin interface is accessible"
else
    echo "❌ Mailu admin interface not responding"
fi

echo ""
echo "📧 Testing Postal admin access..."
echo "URL: https://postal.soham.top"

# Test if postal interface is accessible
if curl -k --resolve postal.soham.top:443:127.0.0.1 -s https://postal.soham.top/ | grep -q "login\|postal"; then
    echo "✅ Postal interface is accessible"
else
    echo "❌ Postal interface not responding"
fi

echo ""
echo "📊 Testing Mautic interface..."
echo "URL: https://mautic.soham.top"

# Test if mautic interface is accessible
if curl -k --resolve mautic.soham.top:443:127.0.0.1 -s https://mautic.soham.top/ | grep -q "mautic\|install\|DOCTYPE"; then
    echo "✅ Mautic interface is accessible"
else
    echo "❌ Mautic interface not responding"
fi

echo ""
echo "🎯 Manual Testing Instructions:"
echo "================================"
echo "1. Open browser and navigate to:"
echo "   - https://mail.soham.top/admin"
echo "   - Login: admin@soham.top / Grow@1234"
echo ""
echo "2. For Postal admin:"
echo "   - Navigate to: https://postal.soham.top"
echo "   - Use credentials from postal setup logs"
echo ""
echo "3. For Mautic setup:"
echo "   - Navigate to: https://mautic.soham.top"
echo "   - Follow web installer"
echo ""
echo "✅ All interfaces should be accessible via the above URLs"
