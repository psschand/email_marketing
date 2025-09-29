#!/bin/bash

# =============================================================================
# Quick Postal Password Reset
# =============================================================================
# Reset password for admin@soham.top in Postal
# =============================================================================

echo "🔑 Resetting Postal admin password..."

USER_EMAIL="admin@soham.top"
NEW_PASSWORD="Grow@1234"

echo "Setting password for $USER_EMAIL to: $NEW_PASSWORD"

# Use Rails console to reset password
docker exec postal-web-1 bash -c "
echo \"
user = User.find_by(email_address: '$USER_EMAIL')
if user
  user.password = '$NEW_PASSWORD'
  user.password_confirmation = '$NEW_PASSWORD'
  if user.save
    puts '✅ Password updated successfully for $USER_EMAIL'
    puts '🔗 Login at: https://postal.soham.top'
    puts '📧 Email: $USER_EMAIL'
    puts '🔑 Password: $NEW_PASSWORD'
  else
    puts '❌ Failed to update password: ' + user.errors.full_messages.join(', ')
  end
else
  puts '❌ User $USER_EMAIL not found'
  puts '📋 Available admin users:'
  User.where(admin: true).each { |u| puts '   - ' + u.email_address }
end
\" | postal console
" && echo "" && echo "✅ Postal password reset completed!" || echo "❌ Password reset failed"

echo ""
echo "🌐 Test login at: https://postal.soham.top"
echo "📧 Email: $USER_EMAIL"
echo "🔑 Password: $NEW_PASSWORD"
