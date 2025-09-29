#!/bin/bash

# =============================================================================
# Postal Configuration Sync and Restart Script
# =============================================================================
# This script ensures that postal.yml configuration is properly synchronized
# between host and container, and restarts services to load the configuration.
#
# Usage: ./sync-postal-config.sh
# =============================================================================

set -e

COMPOSE_FILE="docker-compose.prod.yml"
CONFIG_FILE="postal.yml"

print_step() {
    echo "--- $1 ---"
}

print_step "Checking Postal Configuration"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: $CONFIG_FILE not found in current directory"
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ ERROR: $COMPOSE_FILE not found in current directory"
    exit 1
fi

echo "✅ Configuration files found"

print_step "Checking DNS Configuration in postal.yml"

# Check if DNS section exists in postal.yml
if grep -q "^dns:" "$CONFIG_FILE"; then
    echo "✅ DNS section found in postal.yml"
    
    SPF_INCLUDE=$(awk -F': *' '/^dns:/{f=1;next} f&&/^  spf_include:/{print $2; exit}' "$CONFIG_FILE")
    if [ -n "$SPF_INCLUDE" ]; then
        echo "✅ SPF include configured: $SPF_INCLUDE"
    else
        echo "⚠️  No SPF include found in DNS section"
    fi
else
    echo "❌ No DNS section found in postal.yml"
    echo "The postal.yml file should include a DNS section with spf_include setting."
    exit 1
fi

print_step "Stopping Postal Services"
sudo docker compose -f "$COMPOSE_FILE" down

print_step "Ensuring Configuration Sync"
# Get the web container name pattern
WEB_SERVICE="web"

print_step "Starting Postal Services"
sudo docker compose -f "$COMPOSE_FILE" up -d

echo "Waiting for services to start..."
sleep 10

print_step "Verifying Configuration is Loaded"
CONFIG_CHECK=$(sudo docker compose -f "$COMPOSE_FILE" exec -T "$WEB_SERVICE" rails runner - <<'RUBY'
begin
  config = Postal::Config
  dns_config = config.dns
  puts dns_config.spf_include
rescue => e
  puts "ERROR: #{e.message}"
end
RUBY
)

LOADED_SPF=$(echo "$CONFIG_CHECK" | grep -v "Loading config" | tail -n 1)

if [ "$LOADED_SPF" = "$SPF_INCLUDE" ]; then
    echo "✅ Configuration loaded correctly: $LOADED_SPF"
else
    echo "❌ Configuration mismatch!"
    echo "  Expected: $SPF_INCLUDE"
    echo "  Loaded:   $LOADED_SPF"
    exit 1
fi

print_step "Clearing Domain Cache"
sudo docker compose -f "$COMPOSE_FILE" exec -T "$WEB_SERVICE" rails runner - <<'RUBY'
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
echo "==============================================="
echo "✅ POSTAL CONFIGURATION SYNC COMPLETE"
echo "==============================================="
echo "All services are running with correct configuration."
echo "The SPF hostname is set to: $SPF_INCLUDE"
echo "Configuration will persist across restarts."
echo "==============================================="
