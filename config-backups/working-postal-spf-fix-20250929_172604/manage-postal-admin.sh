#!/bin/bash

# =============================================================================
# Postal Admin User Management
# =============================================================================
# This script manages Postal admin user credentials
# =============================================================================

echo "📧 Postal Admin User Management"
echo "================================"

# Check if postal containers are running
if ! docker ps --format '{{.Names}}' | grep -q "postal-web-1"; then
    echo "❌ postal-web-1 container is not running. Please start Postal services first."
    exit 1
fi

echo "📋 Current Postal Users:"
docker exec postal-db-1 mysql -u root -ppostal_root_password -e "SELECT id, email_address, admin, created_at FROM postal.users ORDER BY id;" 2>/dev/null

echo ""
echo "🔧 Postal Admin Options:"
echo "========================"
echo "1. Create new admin user"
echo "2. Reset password for existing user (via Rails console)"
echo "3. Show login instructions"
echo ""

read -p "Choose option (1-3): " choice

case $choice in
    1)
        echo "📝 Creating new Postal admin user..."
        echo "Note: This will prompt for email and password interactively"
        docker exec -it postal-web-1 postal make-user
        ;;
    2)
        echo "🔑 Resetting password for existing user..."
        echo "Available users:"
        docker exec postal-db-1 mysql -u root -ppostal_root_password -e "SELECT id, email_address FROM postal.users WHERE admin=1;" 2>/dev/null
        
        read -p "Enter user email: " user_email
        read -p "Enter new password: " new_password
        
        echo "Resetting password for $user_email..."
        
        # Use Rails console to reset password
        docker exec postal-web-1 postal console -e "
        user = User.find_by(email_address: '$user_email')
        if user
          user.password = '$new_password'
          user.password_confirmation = '$new_password'
          if user.save
            puts 'Password updated successfully for $user_email'
          else
            puts 'Failed to update password: ' + user.errors.full_messages.join(', ')
          end
        else
          puts 'User $user_email not found'
        end
        exit
        " 2>/dev/null && echo "✅ Password reset completed" || echo "❌ Password reset failed"
        ;;
    3)
        echo "🌐 Postal Login Instructions:"
        echo "============================="
        echo "1. Navigate to: https://postal.soham.top"
        echo "2. Use one of these accounts:"
        echo ""
        docker exec postal-db-1 mysql -u root -ppostal_root_password -e "SELECT CONCAT('   Email: ', email_address) as 'Admin Users' FROM postal.users WHERE admin=1;" 2>/dev/null
        echo ""
        echo "🔧 If you don't know the password:"
        echo "• Run this script again and choose option 2 to reset"
        echo "• Or check Postal setup logs for original credentials"
        echo ""
        echo "🔑 Common default passwords to try:"
        echo "• password"
        echo "• admin"
        echo "• The password set during initial setup"
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "📋 Final Status:"
echo "Admin users in Postal:"
docker exec postal-db-1 mysql -u root -ppostal_root_password -e "SELECT email_address, admin, created_at FROM postal.users WHERE admin=1;" 2>/dev/null
