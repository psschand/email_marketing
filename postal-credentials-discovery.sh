#!/bin/bash

# =============================================================================
# Postal Admin Credentials Discovery Script
# =============================================================================
# Lists all possible Postal admin accounts and suggests credentials to try
# =============================================================================

echo "🔍 POSTAL ADMIN CREDENTIALS DISCOVERY"
echo "====================================="

echo ""
echo "📋 ALL POSTAL USERS:"
echo "===================="
docker exec postal-db-1 mysql -u root -ppostal_root_password -e "
SELECT 
    id,
    email_address as 'Email',
    CONCAT(first_name, ' ', last_name) as 'Name',
    CASE WHEN admin = 1 THEN 'ADMIN' ELSE 'USER' END as 'Role',
    created_at as 'Created'
FROM postal.users 
ORDER BY admin DESC, id;
" 2>/dev/null

echo ""
echo "🔑 POSSIBLE CREDENTIALS TO TRY:"
echo "==============================="

echo "For admin@localhost:"
echo "• Email: admin@localhost"
echo "• Possible passwords:"
echo "  - password"
echo "  - admin"
echo "  - localhost"
echo "  - postal"
echo "  - The password you set during initial setup"
echo ""

echo "For admin@soham.top:"
echo "• Email: admin@soham.top"
echo "• Possible passwords:"
echo "  - Grow@1234 (recently set by our script)"
echo "  - password"
echo "  - admin"
echo "  - postal"
echo "  - The password from initial manual creation"
echo ""

echo "For sun@sun.com:"
echo "• Email: sun@sun.com (not admin)"
echo "• This is a regular user, not admin"
echo ""

echo "🌐 LOGIN TESTING:"
echo "================="
echo "1. Go to: https://postal.soham.top"
echo "2. Try these combinations:"
echo ""
echo "   Option 1: admin@localhost"
echo "   Passwords to try: password, admin, postal, localhost"
echo ""
echo "   Option 2: admin@soham.top"
echo "   Passwords to try: Grow@1234, password, admin, postal"
echo ""

echo "🔧 RESET CREDENTIALS:"
echo "===================="
echo "If none work, run these commands:"
echo ""

echo "Reset admin@localhost password:"
echo "docker exec postal-web-1 bash -c \"echo \\\"
user = User.find_by(email_address: 'admin@localhost')
if user
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.save!
  puts 'Password for admin@localhost set to: password123'
end
\\\" | postal console\""
echo ""

echo "Reset admin@soham.top password:"
echo "docker exec postal-web-1 bash -c \"echo \\\"
user = User.find_by(email_address: 'admin@soham.top')
if user
  user.password = 'Grow@1234'
  user.password_confirmation = 'Grow@1234'
  user.save!
  puts 'Password for admin@soham.top set to: Grow@1234'
end
\\\" | postal console\""
echo ""

echo "🆕 CREATE NEW ADMIN USER:"
echo "========================="
echo "docker exec -it postal-web-1 postal make-user"
echo ""

echo "📝 NOTES:"
echo "========="
echo "• The original admin@localhost was created during initial Postal setup"
echo "• The admin@soham.top was created later manually"
echo "• CSRF errors in logs suggest login attempts are reaching the server"
echo "• Try clearing browser cache/cookies for postal.soham.top"
echo "• Ensure you're accessing via https://postal.soham.top (not localhost)"

echo ""
echo "🚨 MOST LIKELY WORKING CREDENTIALS:"
echo "==================================="
echo "Email: admin@localhost"
echo "Password: password (or admin)"
echo ""
echo "Email: admin@soham.top"  
echo "Password: Grow@1234"
echo ""
echo "URL: https://postal.soham.top"
