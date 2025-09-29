#!/usr/bin/env bash
set -e

# =============================================================================
# Postal Mail Server Complete Setup Script
# =============================================================================
# This script combines all postal setup functions into a single comprehensive tool
# 1. Initial server setup with database permissions
# 2. Default organization and user creation  
# 3. Domain and SMTP credential setup
# 4. Test email sending capability
# 5. Interactive menu for management tasks
#
# Usage: 
#   ./postal-setup-complete.sh init                           # Initial server setup
#   ./postal-setup-complete.sh users                          # Create default users
#   ./postal-setup-complete.sh domain <domain> <test-email>   # Setup domain + send test
#   ./postal-setup-complete.sh full <domain> <test-email>     # Complete setup (all steps)
#   ./postal-setup-complete.sh menu                           # Interactive menu
#   ./postal-setup-complete.sh                                # Interactive menu (default)
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

# You can override DEFAULT_DOMAIN/EMAILS via environment variables before running the script
# e.g. DEFAULT_DOMAIN=soham.top ADMIN_EMAIL=admin@soham.top ./postal-setup-complete.sh users
DEFAULT_DOMAIN="${DEFAULT_DOMAIN:-soham.top}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DEFAULT_DOMAIN}}"
ADMIN_NAME="Admin User"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-changeme}"
NORMAL_USER_EMAIL="${NORMAL_USER_EMAIL:-user@${DEFAULT_DOMAIN}}"
NORMAL_USER_NAME="Normal User"
NORMAL_USER_PASSWORD="${NORMAL_USER_PASSWORD:-changeme}"

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

load_values_from_postal_yml() {
    # Derive BASE_DOMAIN, ADMIN/USER emails from postal.yml
    local YML="postal.yml"
    if [ ! -f "$YML" ]; then
        echo "ERROR: $YML not found next to this script." >&2
        return 1
    fi

    # Extract web.host or fallback to postal.web_hostname
    local WEB_HOST
    WEB_HOST=$(awk -F': *' '/^web:/{f=1;next} f&&/^  host:/{print $2; exit}' "$YML")
    if [ -z "$WEB_HOST" ]; then
        WEB_HOST=$(awk -F': *' '/^postal:/{f=1;next} f&&/^  web_hostname:/{print $2; exit}' "$YML")
    fi

    # Extract dns.smtp_server_hostname, fallback to WEB_HOST
    local SMTP_HOST
    SMTP_HOST=$(awk -F': *' '/^dns:/{f=1;next} f&&/^  smtp_server_hostname:/{print $2; exit}' "$YML")
    [ -z "$SMTP_HOST" ] && SMTP_HOST="$WEB_HOST"

    # Derive base domain as last two labels of SMTP_HOST (best-effort)
    local DERIVED_BASE
    DERIVED_BASE=$(echo "$SMTP_HOST" | awk -F. '{ if (NF>=2) print $(NF-1)"."$NF; else print $0 }')
    [ -z "$DERIVED_BASE" ] && DERIVED_BASE="$DEFAULT_DOMAIN"

    DERIVED_BASE_DOMAIN="$DERIVED_BASE"
    DERIVED_ADMIN_EMAIL="admin@$DERIVED_BASE"
    DERIVED_USER_EMAIL="user@$DERIVED_BASE"
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
    sudo docker compose -f "$COMPOSE_FILE" up -d
    wait_for_services
    
    print_step "Applying Database Permissions"
    sudo docker compose -f "$COMPOSE_FILE" exec -T db mysql -u root -ppostal_root_password <<'SQL'
GRANT ALL PRIVILEGES ON *.* TO 'postal'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
    echo "Database permissions applied successfully."
    
    print_step "Creating Initial Admin User"
    echo "Please follow the prompts below to create your admin account."
    sudo docker compose -f "$COMPOSE_FILE" exec web postal make-user
    
    echo -e "\n✅ Initial server setup complete!"
    echo "You can access the web interface at http://<your-server-ip>:5000"
}

setup_default_users() {
    print_header "CREATING DEFAULT USERS AND ORGANIZATION"
    
    check_compose_file
    
        print_step "Creating Organization and Users"
        sudo docker compose -f "$COMPOSE_FILE" exec -T web postal console <<RUBY
begin
    puts "__OUT__ Creating users/org"
    # Step 1: Create the default organization
    puts "__OUT__ Creating organization: '$ORG_NAME'..."
    org = Organization.find_or_create_by!(name: '$ORG_NAME', permalink: '$ORG_PERMALINK')
    puts "__OUT__ Organization created successfully."

    # Step 2: Create the admin user
    puts "__OUT__ Creating admin user: '$ADMIN_EMAIL'..."
    unless User.exists?(email: '$ADMIN_EMAIL')
        User.create!(
            email: '$ADMIN_EMAIL',
            first_name: 'Admin',
            last_name: 'User',
            password: '$ADMIN_PASSWORD',
            password_confirmation: '$ADMIN_PASSWORD',
            admin: 1
        )
    puts "__OUT__ Admin user created successfully."
    else
    puts "__OUT__ Admin user '$ADMIN_EMAIL' already exists."
    end

    # Step 3: Create the normal user and associate them with the default organization (best-effort)
    puts "__OUT__ Creating normal user: '$NORMAL_USER_EMAIL'..."
    unless User.exists?(email: '$NORMAL_USER_EMAIL')
        normal_user = User.new(
            email: '$NORMAL_USER_EMAIL',
            first_name: 'Normal',
            last_name: 'User',
            password: '$NORMAL_USER_PASSWORD',
            password_confirmation: '$NORMAL_USER_PASSWORD',
            admin: 0
        )
        begin
            normal_user.servers << org.servers.first if org.respond_to?(:servers) && org.servers.any?
        rescue => _
            # association may differ by Postal version; continue without linking
        end
        normal_user.save!
        puts "__OUT__ Normal user created successfully."
    else
        puts "__OUT__ Normal user '$NORMAL_USER_EMAIL' already exists."
    end
    puts "__OUT__ Done"
    nil
rescue => e
    puts "RUBY_ERROR:#{e.message}"
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
    puts "[DATA_START]"
    # Find or create the organization
    org = Organization.find_or_create_by!(name: '$ORG_NAME')

    # Find or create the mail server
    server = (org.respond_to?(:servers) ? org.servers : Server).find_or_create_by!(name: '$DOMAIN') { |s| s.mode = 'Live' if s.respond_to?(:mode=) }

    # Find or create an SMTP credential for the server
    cred_scope = server.respond_to?(:credentials) ? server.credentials : Credential
    credential = cred_scope.find_or_create_by!(type: 'SMTP', name: 'smtp-user')

    # Output the necessary values for authentication with clear markers
    puts "SERVER_TOKEN:#{server.token}"
    puts "CREDENTIAL_KEY:#{credential.key}"
    puts "[DATA_END]"
    nil
rescue => e
    puts "RUBY_ERROR:#{e.message}"
end
RUBY
)

    # Check if the setup command was successful
    if [ $? -ne 0 ] || echo "$CREDENTIAL_OUTPUT" | grep -q "RUBY_ERROR"; then
        echo "❌ Postal setup command failed. Aborting."
        echo "--- Raw Error Output ---"
        echo "$CREDENTIAL_OUTPUT"
        echo "------------------------"
        exit 1
    fi

    print_step "Extracting Credentials"
    local AUTH_USER=$(echo "$CREDENTIAL_OUTPUT" | sed -n '/\[DATA_START\]/,/\[DATA_END\]/p' | grep 'SERVER_TOKEN:' | tail -n 1 | cut -d':' -f2)
    local AUTH_PASS=$(echo "$CREDENTIAL_OUTPUT" | sed -n '/\[DATA_START\]/,/\[DATA_END\]/p' | grep 'CREDENTIAL_KEY:' | tail -n 1 | cut -d':' -f2)

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

show_validated_domains() {
    print_header "VALIDATED DOMAINS"
    
    check_compose_file
    
    print_step "Retrieving Domains from Database"
        local DOMAINS_OUTPUT=$(sudo docker compose -f "$COMPOSE_FILE" exec -T "$SERVICE_NAME" postal console <<'RUBY'
begin
        puts "__OUT__ START"
    domains = Domain.all
    if domains.empty?
            puts "__OUT__ No domains found."
    else
            puts "__OUT__ All Domains and Their Status:"
            puts "__OUT__ " + ("=" * 60)
        domains.each do |domain|
            org_name = (domain.server && domain.server.respond_to?(:organization) && domain.server.organization ? domain.server.organization.name : 'N/A')
            srv_name = (domain.server && domain.server.respond_to?(:name) ? domain.server.name : 'N/A')
            dkim = (domain.respond_to?(:dkim_status) ? domain.dkim_status : 'N/A')
            mx = (domain.respond_to?(:mx_status) ? domain.mx_status : 'N/A')
            spf = (domain.respond_to?(:spf_status) ? domain.spf_status : 'N/A')
            rp = (domain.respond_to?(:return_path_status) ? domain.return_path_status : 'N/A')
            validated = (dkim == 'OK' && mx == 'OK' && rp == 'OK' && spf == 'OK') ? 'Yes' : 'No'
                puts "__OUT__ Domain: #{domain.name}"
                puts "__OUT__   Organization: #{org_name}"
                puts "__OUT__   Server: #{srv_name}"
                puts "__OUT__   DKIM: #{dkim}"
                puts "__OUT__   MX: #{mx}"
                puts "__OUT__   SPF: #{spf}"
                puts "__OUT__   Return Path: #{rp}"
                puts "__OUT__   Fully Validated: #{validated}"
                puts "__OUT__"
        end
    end
        puts "__OUT__ END"
    nil
rescue => e
    puts "RUBY_ERROR:#{e.message}"
end
RUBY
)
            echo "$DOMAINS_OUTPUT" | grep '^__OUT__' | sed 's/^__OUT__ \{0,1\}//'
}

send_test_email_from_validated() {
    print_header "SEND TEST EMAIL FROM DOMAIN WITH SMTP CREDENTIALS"
    
    check_compose_file
    
        # Get domains and associated server token; only include domains that have at least one SMTP credential
        local DOMAIN_ROWS=$(sudo docker compose -f "$COMPOSE_FILE" exec -T "$SERVICE_NAME" postal console <<'RUBY'
begin
        puts "__OUT__ START"
    Domain.all.each do |domain|
        server = domain.server rescue nil
        next unless server
        # check for at least one SMTP credential
        creds = (server.respond_to?(:credentials) ? server.credentials : Credential).where(type: 'SMTP') rescue []
        next if creds.nil? || creds.empty?
        org_name = (server.respond_to?(:organization) && server.organization ? server.organization.name : 'N/A')
            puts "__OUT__ " + [domain.name, org_name, server.token].join('|')
    end
        puts "__OUT__ END"
    nil
rescue => e
    puts "RUBY_ERROR:#{e.message}"
end
RUBY
)
            DOMAIN_ROWS=$(echo "$DOMAIN_ROWS" | grep '^__OUT__' | sed 's/^__OUT__ \{0,1\}//' | sed '/^START$/d;/^END$/d')
        if [ -z "$DOMAIN_ROWS" ]; then
                echo "❌ No domains with SMTP credentials found. Please set up a domain and credentials first."
                return 1
        fi
        echo "Available Domains with SMTP Credentials:"
        echo "=========================================="
        local i=1
        local DOMAIN_LIST=()
        while IFS='|' read -r domain org token; do
                [ -z "$domain" ] && continue
                echo "$i. $domain (Org: $org)"
                DOMAIN_LIST+=("$domain|$org|$token")
                ((i++))
        done <<< "$DOMAIN_ROWS"
    
    echo
    read -p "Select domain number: " domain_choice
    
    if ! [[ "$domain_choice" =~ ^[0-9]+$ ]] || [ "$domain_choice" -lt 1 ] || [ "$domain_choice" -gt "${#DOMAIN_LIST[@]}" ]; then
        echo "❌ Invalid selection."
        return 1
    fi
    
    IFS='|' read -r SELECTED_DOMAIN ORG_NAME SERVER_TOKEN <<< "${DOMAIN_LIST[$((domain_choice-1))]}"
    
    read -p "Recipient email address: " RECIPIENT_EMAIL
    if [ -z "$RECIPIENT_EMAIL" ]; then
        echo "❌ Recipient email is required."
        return 1
    fi
    
    read -p "From email (leave blank for info@$SELECTED_DOMAIN): " FROM_EMAIL
    FROM_EMAIL=${FROM_EMAIL:-"info@$SELECTED_DOMAIN"}
    
    read -p "Subject (leave blank for default): " SUBJECT
    SUBJECT=${SUBJECT:-"Test Email from $SELECTED_DOMAIN via Postal"}
    
    read -p "Message body (leave blank for default): " BODY
    BODY=${BODY:-"This is a test email sent from $SELECTED_DOMAIN using Postal mail server."}
    
    print_step "Retrieving SMTP Credentials"
    
        local CREDENTIAL_OUTPUT=$(sudo docker compose -f "$COMPOSE_FILE" exec -T "$SERVICE_NAME" postal console <<RUBY
begin
        puts "__OUT__ START"
    server = Server.find_by(token: '$SERVER_TOKEN')
    if server
        cred = (server.respond_to?(:credentials) ? server.credentials : Credential).find_by(type: 'SMTP', name: 'smtp-user')
        if cred
                puts "__OUT__ CREDENTIAL_KEY:#{cred.key}"
        else
                puts "__OUT__ ERROR: SMTP credential not found"
        end
    else
            puts "__OUT__ ERROR: Server not found"
    end
        puts "__OUT__ END"
    nil
rescue => e
    puts "RUBY_ERROR:#{e.message}"
end
RUBY
)
    
    if echo "$CREDENTIAL_OUTPUT" | grep -q "^ERROR"; then
        echo "❌ Failed to retrieve SMTP credentials: $CREDENTIAL_OUTPUT"
        return 1
    fi
    
    local AUTH_PASS=$(echo "$CREDENTIAL_OUTPUT" | grep '^__OUT__' | sed 's/^__OUT__ \{0,1\}//' | grep 'CREDENTIAL_KEY:' | cut -d':' -f2)
    
    if [ -z "$AUTH_PASS" ]; then
        echo "❌ Failed to extract credential key."
        return 1
    fi
    
    print_step "Sending Test Email"
    echo "From: $FROM_EMAIL"
    echo "To: $RECIPIENT_EMAIL"
    echo "Subject: $SUBJECT"
    echo
    
    # Check if swaks is available
    if ! command -v swaks &> /dev/null; then
        echo "⚠️  swaks not found. Installing..."
        sudo apt update && sudo apt install -y swaks
    fi
    
    swaks \
        --to "$RECIPIENT_EMAIL" \
        --from "$FROM_EMAIL" \
        --server "$SMTP_SERVER:$SMTP_PORT" \
        --auth-user "$SERVER_TOKEN" \
        --auth-password "$AUTH_PASS" \
        --header "Subject: $SUBJECT" \
        --body "$BODY"
    
    if [ $? -eq 0 ]; then
        echo "✅ Test email sent successfully!"
    else
        echo "❌ Failed to send test email."
        return 1
    fi
}

update_database_hostnames() {
    print_header "UPDATE DATABASE HOSTNAMES FROM POSTAL.YML"

    check_compose_file

    # Load values from postal.yml and derive base domain and default emails
    if ! load_values_from_postal_yml; then
        echo "❌ Could not read values from postal.yml"
        return 1
    fi

    local BASE_DOMAIN
    BASE_DOMAIN="${DERIVED_BASE_DOMAIN:-$DEFAULT_DOMAIN}"
    if [ -z "$BASE_DOMAIN" ]; then
        echo "❌ Base domain is required."
        return 1
    fi

    local NEW_ADMIN_EMAIL
    NEW_ADMIN_EMAIL="${DERIVED_ADMIN_EMAIL:-admin@${BASE_DOMAIN}}"

    local NEW_USER_EMAIL
    NEW_USER_EMAIL="${DERIVED_USER_EMAIL:-user@${BASE_DOMAIN}}"

    echo "Proposed updates (from postal.yml):"
    echo "  Base domain: $BASE_DOMAIN"
    echo "  Admin email: $NEW_ADMIN_EMAIL"
    echo "  User email:  $NEW_USER_EMAIL"
    read -p "Proceed with these changes? (y/N): " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        return 0
    fi

    print_step "Updating database records"
    
    # Get the current hostname from postal.yml for comparison
    local CURRENT_HOSTNAME
    CURRENT_HOSTNAME=$(awk -F': *' '/^web:/{f=1;next} f&&/^  host:/{print $2; exit}' postal.yml)
    if [ -z "$CURRENT_HOSTNAME" ]; then
        CURRENT_HOSTNAME=$(awk -F': *' '/^postal:/{f=1;next} f&&/^  web_hostname:/{print $2; exit}' postal.yml)
    fi
    [ -z "$CURRENT_HOSTNAME" ] && CURRENT_HOSTNAME="postal.soham.top"
    
    # Get SPF hostname for fixing error messages
    local SPF_HOSTNAME
    SPF_HOSTNAME=$(awk -F': *' '/^dns:/{f=1;next} f&&/^  spf_include:/{print $2; exit}' postal.yml)
    [ -z "$SPF_HOSTNAME" ] && SPF_HOSTNAME="spf.postal.soham.top"
    
    echo "Current hostname from postal.yml: $CURRENT_HOSTNAME"
    echo "SPF hostname from postal.yml: $SPF_HOSTNAME"
    
    local OUTPUT=$(sudo docker compose -f "$COMPOSE_FILE" exec -T "$SERVICE_NAME" rails runner - <<RUBY
begin
    puts "__OUT__ START"

    changes = []
    updated = 0

    # Update default placeholder users if present (robust to schema differences)
    begin
        if ActiveRecord::Base.connection.table_exists?(:users)
            cols = ActiveRecord::Base.connection.columns(:users).map(&:name) rescue []
            email_col = if cols.include?("email")
                "email"
            elsif cols.include?("email_address")
                "email_address"
            else
                nil
            end

            if email_col
                # Use current hostname from postal.yml
                current_hostname = '${CURRENT_HOSTNAME}'
                placeholder_admin = "admin@" + current_hostname
                placeholder_user = "user@" + current_hostname
                
                admin_user = begin
                    User.where(email_col => placeholder_admin).first
                rescue => _
                    nil
                end
                if admin_user
                    admin_user.update(email_col => '${NEW_ADMIN_EMAIL}')
                    updated += 1
                    changes << "User: #{placeholder_admin} -> ${NEW_ADMIN_EMAIL}"
                end

                normal_user = begin
                    User.where(email_col => placeholder_user).first
                rescue => _
                    nil
                end
                if normal_user
                    normal_user.update(email_col => '${NEW_USER_EMAIL}')
                    updated += 1
                    changes << "User: #{placeholder_user} -> ${NEW_USER_EMAIL}"
                end
            else
                puts "__OUT__ Skipped user email updates: no email/email_address column"
            end
        else
            puts "__OUT__ Skipped user email updates: users table missing"
        end
    rescue => e
        puts "__OUT__ Skipped user email updates due to error: #{e.class}: #{e.message}"
    end

    # Update any Domain with placeholder name (safe-guard on table)
    begin
        if ActiveRecord::Base.connection.table_exists?(:domains)
            # Use current hostname from postal.yml
            current_hostname = '${CURRENT_HOSTNAME}'
            Domain.where(name: current_hostname).find_each do |d|
                d.update(name: '${BASE_DOMAIN}')
                updated += 1
                changes << "Domain: #{current_hostname} -> ${BASE_DOMAIN}"
            end
        else
            puts "__OUT__ Skipped domain updates: domains table missing"
        end
    rescue => e
        puts "__OUT__ Skipped domain updates due to error: #{e.class}: #{e.message}"
    end

    # Update any Server with placeholder name (safe-guard on table)
    begin
        if ActiveRecord::Base.connection.table_exists?(:servers)
            # Use current hostname from postal.yml
            current_hostname = '${CURRENT_HOSTNAME}'
            Server.where(name: current_hostname).find_each do |s|
                s.update(name: '${BASE_DOMAIN}')
                updated += 1
                changes << "Server: #{current_hostname} -> ${BASE_DOMAIN}"
            end
        else
            puts "__OUT__ Skipped server updates: servers table missing"
        end
    rescue => e
        puts "__OUT__ Skipped server updates due to error: #{e.class}: #{e.message}"
    end

    # Fix SPF error messages that reference old example.com domains
    begin
        if ActiveRecord::Base.connection.table_exists?(:domains)
            spf_hostname = '${SPF_HOSTNAME}'
            old_spf_patterns = ['spf.postal.example.com', 'spf.example.com']
            
            Domain.all.each do |domain|
                domain_changes = []
                
                ['spf_error', 'mx_error', 'dkim_error', 'return_path_error', 'verification_token', 'notes'].each do |field|
                    if domain.respond_to?(field) && domain.send(field).to_s.present?
                        old_value = domain.send(field)
                        new_value = old_value
                        
                        old_spf_patterns.each do |old_pattern|
                            if new_value.include?(old_pattern)
                                new_value = new_value.gsub(old_pattern, spf_hostname)
                            end
                        end
                        
                        if new_value != old_value
                            domain.update!(field => new_value)
                            domain_changes << "#{field}: example.com references -> #{spf_hostname}"
                        end
                    end
                end
                
                if domain_changes.any?
                    updated += 1
                    changes << "Domain #{domain.name} SPF fixes: #{domain_changes.join(', ')}"
                end
            end
        end
    rescue => e
        puts "__OUT__ Skipped SPF error fixes due to error: #{e.class}: #{e.message}"
    end

    if changes.empty?
        puts "__OUT__ No placeholder records found. Nothing to update."
    else
        puts "__OUT__ Updated records:"
        changes.each { |c| puts "__OUT__   - #{c}" }
    end

    puts "__OUT__ SUMMARY: updated=#{updated}"
    puts "__OUT__ END"
    nil
rescue => e
    puts "RUBY_ERROR:#{e.class}: #{e.message}"
end
RUBY
)

        if echo "$OUTPUT" | grep -q "RUBY_ERROR:"; then
                echo "❌ Failed to update database hostnames:"
                echo "$OUTPUT"
                return 1
        fi

    local OUT_ONLY
    OUT_ONLY=$(echo "$OUTPUT" | grep '^__OUT__' | sed 's/^__OUT__ \{0,1\}//')
    if [ -n "$OUT_ONLY" ]; then
        echo "$OUT_ONLY"
    else
        echo "No DB changes detected. Raw output:"
        echo "$OUTPUT"
    fi
}

sync_configuration_and_restart() {
    print_header "SYNC CONFIGURATION AND RESTART SERVICES"

    check_compose_file

    print_step "Checking postal.yml configuration"
    
    # Check if DNS section exists
    if ! grep -q "^dns:" postal.yml; then
        echo "❌ No DNS section found in postal.yml"
        echo "The postal.yml file should include a DNS section with spf_include setting."
        return 1
    fi
    
    local SPF_INCLUDE
    SPF_INCLUDE=$(awk -F': *' '/^dns:/{f=1;next} f&&/^  spf_include:/{print $2; exit}' postal.yml)
    if [ -z "$SPF_INCLUDE" ]; then
        echo "❌ No spf_include found in DNS section"
        return 1
    fi
    
    echo "✅ Found SPF include: $SPF_INCLUDE"
    
    print_step "Restarting Postal services to sync configuration"
    sudo docker compose -f "$COMPOSE_FILE" down
    sudo docker compose -f "$COMPOSE_FILE" up -d
    
    echo "Waiting for services to start..."
    sleep 10
    
    print_step "Verifying configuration is loaded correctly"
    
    local CONFIG_CHECK
    CONFIG_CHECK=$(sudo docker compose -f "$COMPOSE_FILE" exec -T "$SERVICE_NAME" rails runner - <<'RUBY'
begin
  config = Postal::Config
  dns_config = config.dns
  puts dns_config.spf_include
rescue => e
  puts "ERROR: #{e.message}"
end
RUBY
)
    
    local LOADED_SPF
    LOADED_SPF=$(echo "$CONFIG_CHECK" | grep -v "Loading config" | tail -n 1)
    
    if [ "$LOADED_SPF" = "$SPF_INCLUDE" ]; then
        echo "✅ Configuration loaded correctly: $LOADED_SPF"
    else
        echo "❌ Configuration mismatch!"
        echo "  Expected: $SPF_INCLUDE"
        echo "  Loaded:   $LOADED_SPF"
        return 1
    fi
    
    print_step "Clearing domain cache and re-validating"
    
    sudo docker compose -f "$COMPOSE_FILE" exec -T "$SERVICE_NAME" rails runner - <<'RUBY'
begin
  Domain.all.each do |domain|
    domain.update!(
      dns_checked_at: nil,
      spf_status: nil,
      spf_error: nil,
      mx_status: nil,
      mx_error: nil,
      dkim_status: nil,
      dkim_error: nil,
      return_path_status: nil,
      return_path_error: nil
    )
    domain.check_dns if domain.respond_to?(:check_dns)
  end
  puts "Domain cache cleared and re-validated"
rescue => e
  puts "ERROR: #{e.message}"
end
RUBY
    
    echo ""
    echo "✅ Configuration sync complete!"
    echo "SPF hostname: $SPF_INCLUDE"
    echo "All services are running with correct configuration."
}

show_interactive_menu() {
    while true; do
        print_header "POSTAL MANAGEMENT MENU"
        echo "1. Show Validated Domains"
        echo "2. Send Test Email from Domain with SMTP Credentials"
        echo "3. Initial Server Setup"
        echo "4. Create Default Users"
        echo "5. Setup Domain and Send Test"
        echo "6. Run Full Setup"
                echo "7. Fix Database Hostnames (update from postal.yml hostname)"
                echo "8. Sync Configuration and Restart Services"
                echo "9. Exit"
        echo
        
                read -p "Choose an option (1-9): " choice
        
        case $choice in
            1)
                show_validated_domains
                ;;
            2)
                send_test_email_from_validated
                ;;
            3)
                setup_initial_server
                ;;
            4)
                setup_default_users
                ;;
            5)
                read -p "Domain: " domain
                read -p "Test email recipient: " email
                if [ -n "$domain" ] && [ -n "$email" ]; then
                    setup_domain_and_test "$domain" "$email"
                else
                    echo "❌ Domain and email are required."
                fi
                ;;
            6)
                read -p "Domain: " domain
                read -p "Test email recipient: " email
                if [ -n "$domain" ] && [ -n "$email" ]; then
                    run_full_setup "$domain" "$email"
                else
                    echo "❌ Domain and email are required."
                fi
                ;;
            7)
                                update_database_hostnames
                                ;;
            8)
                sync_configuration_and_restart
                ;;
                        9)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                                echo "❌ Invalid option. Please choose 1-9."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
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
    echo "  $0 menu                           # Interactive menu"
    echo "  $0                                # Interactive menu (default)"
    echo
    echo "Examples:"
    echo "  $0 full example.com admin@example.com"
    echo "  $0 domain soham.top test@gmail.com"
    echo "  $0 init"
    echo "  $0 users"
    echo "  $0 menu"
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
    "menu")
        show_interactive_menu
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    "")
        show_interactive_menu
        ;;
    *)
        echo "❌ Invalid command: ${1:-}"
        echo
        show_usage
        exit 1
        ;;
esac
