#!/bin/bash
set -e

# =============================================================================
# Postal Mail Server Complete Setup Script
# =============================================================================
# This script combines all postal setup functions into a single comprehensive tool:
# 1. Initial server setup with database permissions
# 2. Default organization and user creation  
# 3. Domain and SMTP credential setup
# 4. Test email sending capability
#
# Usage: 
#   ./postal-setup-complete.sh init                           # Initial server setup
#   ./postal-setup-complete.sh users                          # Create default users
#   ./postal-setup-complete.sh domain <domain> <test-email>   # Setup domain + send test
#   ./postal-setup-complete.sh full <domain> <test-email>     # Complete setup (all steps)
#
# Examples:
#   ./postal-setup-complete.sh full example.com admin@example.com
#   ./postal-setup-complete.sh domain soham.top test@gmail.com
# =============================================================================

COMPOSE_FILE="docker-compose.prod.yml"
SERVICE_NAME="web"
SMTP_SERVER="127.0.0.1"
SMTP_PORT="2525"

# Default user configuration
ORG_NAME="Default Organization"
ORG_PERMALINK="default-organization"
ADMIN_EMAIL="admin@postal.example.com"
ADMIN_NAME="Admin User"
ADMIN_PASSWORD="changeme"
NORMAL_USER_EMAIL="user@postal.example.com"
NORMAL_USER_NAME="Normal User"
NORMAL_USER_PASSWORD="changeme"

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo "==============================================="
    echo "$1"
    echo "==============================================="
}

print_step() {
    echo -e "\n--- $1 ---"
}

check_compose_file() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo "ERROR: $COMPOSE_FILE not found. Please place it in the same directory as this script."
        exit 1
    fi
}

wait_for_services() {
    echo "Services started. Waiting 60 seconds for the database to initialize..."
    sleep 60
}

# =============================================================================
# Setup Functions
# =============================================================================

setup_initial_server() {
    print_header "INITIAL POSTAL SERVER SETUP"
    
    check_compose_file
    
    print_step "Starting Postal Services"
    sudo docker-compose -f "$COMPOSE_FILE" up -d
    wait_for_services
    
    print_step "Applying Database Permissions"
    sudo docker-compose -f "$COMPOSE_FILE" exec -T db mysql -u root -ppostal_root_password <<'SQL'
GRANT ALL PRIVILEGES ON *.* TO 'postal'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
    echo "Database permissions applied successfully."
    
    print_step "Creating Initial Admin User"
    echo "Please follow the prompts below to create your admin account."
    sudo docker-compose -f "$COMPOSE_FILE" exec web postal make-user
    
    echo -e "\n✅ Initial server setup complete!"
    echo "You can access the web interface at http://<your-server-ip>:5000"
}

setup_default_users() {
    print_header "CREATING DEFAULT USERS AND ORGANIZATION"
    
    check_compose_file
    
    print_step "Creating Organization and Users"
    sudo docker-compose -f "$COMPOSE_FILE" exec -T web rails runner <<RUBY
# Step 1: Create the default organization
puts "Creating organization: '$ORG_NAME'..."
org = Organization.find_or_create_by!(name: '$ORG_NAME', permalink: '$ORG_PERMALINK')
puts "Organization created successfully."

# Step 2: Create the admin user
puts "Creating admin user: '$ADMIN_EMAIL'..."
unless User.exists?(email: '$ADMIN_EMAIL')
  User.create!(
    email: '$ADMIN_EMAIL',
    first_name: 'Admin',
    last_name: 'User',
    password: '$ADMIN_PASSWORD',
    password_confirmation: '$ADMIN_PASSWORD',
    admin: 1
  )
  puts "Admin user created successfully."
else
  puts "Admin user '$ADMIN_EMAIL' already exists."
end

# Step 3: Create the normal user and associate them with the default organization
puts "Creating normal user: '$NORMAL_USER_EMAIL'..."
unless User.exists?(email: '$NORMAL_USER_EMAIL')
  normal_user = User.new(
    email: '$NORMAL_USER_EMAIL',
    first_name: 'Normal',
    last_name: 'User',
    password: '$NORMAL_USER_PASSWORD',
    password_confirmation: '$NORMAL_USER_PASSWORD',
    admin: 0
  )
  normal_user.servers << org.servers.first if org.servers.any?
  normal_user.save!
  puts "Normal user created successfully and can access servers in '$ORG_NAME'."
else
  puts "Normal user '$NORMAL_USER_EMAIL' already exists."
end
RUBY

    echo -e "\n✅ Default users setup complete!"
    echo "The following users have been created:"
    echo
    echo "1. Admin User"
    echo "   Email:    $ADMIN_EMAIL"
    echo "   Password: $ADMIN_PASSWORD"
    echo
    echo "2. Normal User"
    echo "   Email:    $NORMAL_USER_EMAIL"
    echo "   Password: $NORMAL_USER_PASSWORD"
}

setup_domain_and_test() {
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 domain <domain> <recipient_email>"
        exit 1
    fi
    
    local DOMAIN=$1
    local RECIPIENT_EMAIL=$2
    local ORG_NAME=$(echo "$DOMAIN" | awk -F. '{print $1}' | sed 's/.*/\u&/')
    local FROM_EMAIL="info@$DOMAIN"
    
    print_header "DOMAIN SETUP AND TEST EMAIL"
    
    check_compose_file
    
    print_step "Setting up Domain and Creating SMTP Credential for: $DOMAIN"
    
    local CREDENTIAL_OUTPUT=$(sudo docker compose -f "$COMPOSE_FILE" exec -T "$SERVICE_NAME" postal console 2>&1 <<RUBY
begin
  # Find or create the organization
  org = Organization.find_or_create_by!(name: '$ORG_NAME')

  # Find or create the mail server
  server = org.servers.find_or_create_by!(name: '$DOMAIN') { |s| s.mode = 'Live' }

  # Find or create an SMTP credential for the server
  credential = server.credentials.find_or_create_by!(type: 'SMTP', name: 'smtp-user')

  # Output the necessary values for authentication.
  puts "SERVER_TOKEN:#{server.token}"
  puts "CREDENTIAL_KEY:#{credential.key}"
rescue => e
  # If any error occurs, print it clearly so the script can capture it.
  puts "RUBY_ERROR:#{e.message}"
end
RUBY
)

    # Check if the setup command was successful
    if [ $? -ne 0 ] || echo "$CREDENTIAL_OUTPUT" | grep -q "^RUBY_ERROR"; then
        echo "❌ Postal setup command failed. Aborting."
        echo "--- Raw Error Output ---"
        echo "$CREDENTIAL_OUTPUT"
        echo "------------------------"
        exit 1
    fi

    print_step "Extracting Credentials"
    local AUTH_USER=$(echo "$CREDENTIAL_OUTPUT" | grep 'SERVER_TOKEN:' | tail -n 1 | cut -d':' -f2)
    local AUTH_PASS=$(echo "$CREDENTIAL_OUTPUT" | grep 'CREDENTIAL_KEY:' | tail -n 1 | cut -d':' -f2)

    if [ -z "$AUTH_USER" ] || [ -z "$AUTH_PASS" ]; then
        echo "❌ Failed to extract credentials from setup script output."
        echo "Raw output:"
        echo "$CREDENTIAL_OUTPUT"
        exit 1
    fi

    echo "✅ Credentials created successfully."
    
    print_step "Sending Test Email from $FROM_EMAIL to $RECIPIENT_EMAIL"
    
    # Check if swaks is available
    if ! command -v swaks &> /dev/null; then
        echo "⚠️  swaks not found. Installing..."
        sudo apt update && sudo apt install -y swaks
    fi
    
    swaks \
        --to "$RECIPIENT_EMAIL" \
        --from "$FROM_EMAIL" \
        --server "$SMTP_SERVER:$SMTP_PORT" \
        --auth-user "$AUTH_USER" \
        --auth-password "$AUTH_PASS" \
        --header "Subject: Test Email from $DOMAIN via Postal" \
        --body "This email was sent using Postal mail server with domain $DOMAIN and SMTP credentials."

    if [ $? -eq 0 ]; then
        echo "✅ Test email sent successfully!"
        echo
        echo "Domain Setup Summary:"
        echo "  Domain: $DOMAIN"
        echo "  Organization: $ORG_NAME"
        echo "  SMTP User: $AUTH_USER" 
        echo "  SMTP Pass: $AUTH_PASS"
        echo "  SMTP Server: $SMTP_SERVER:$SMTP_PORT"
    else
        echo "❌ Failed to send test email. Please check the output above for errors."
        exit 1
    fi
}

run_full_setup() {
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 full <domain> <recipient_email>"
        exit 1
    fi
    
    local DOMAIN=$1
    local RECIPIENT_EMAIL=$2
    
    print_header "COMPLETE POSTAL SETUP"
    echo "This will run all setup steps:"
    echo "1. Initial server setup"
    echo "2. Default users creation"  
    echo "3. Domain setup and test email"
    echo
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    
    setup_initial_server
    sleep 5
    setup_default_users
    sleep 5
    setup_domain_and_test "$DOMAIN" "$RECIPIENT_EMAIL"
    
    print_header "🎉 COMPLETE SETUP FINISHED!"
    echo "Your Postal server is fully configured and ready to use."
    echo "Web interface: http://<your-server-ip>:5000"
}

show_usage() {
    echo "Postal Complete Setup Script"
    echo
    echo "Usage:"
    echo "  $0 init                           # Initial server setup only"
    echo "  $0 users                          # Create default users only"
    echo "  $0 domain <domain> <test-email>   # Setup domain + send test email"
    echo "  $0 full <domain> <test-email>     # Complete setup (all steps)"
    echo
    echo "Examples:"
    echo "  $0 full example.com admin@example.com"
    echo "  $0 domain soham.top test@gmail.com"
    echo "  $0 init"
    echo "  $0 users"
    echo
    echo "This script combines the functionality of:"
    echo "  - setup-new-postal-server.sh"
    echo "  - create-default-user.sh"
    echo "  - setup-and-send-v2.sh"
}

# =============================================================================
# Main Script Logic
# =============================================================================

case "${1:-}" in
    "init")
        setup_initial_server
        ;;
    "users")
        setup_default_users
        ;;
    "domain")
        setup_domain_and_test "${@:2}"
        ;;
    "full")
        run_full_setup "${@:2}"
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        echo "❌ Invalid command: ${1:-}"
        echo
        show_usage
        exit 1
        ;;
esac
