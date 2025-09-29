#!/bin/bash

# =============================================================================
# Test Postal Configuration Reading
# =============================================================================
# Tests that the postal setup script properly reads from postal.yml
# =============================================================================

echo "🔍 TESTING POSTAL CONFIGURATION READING"
echo "========================================"

cd /home/ubuntu/ms/postal

echo ""
echo "📄 Current postal.yml configuration:"
echo "===================================="
echo "Web hostname:"
WEB_HOST=$(awk -F': *' '/^web:/{f=1;next} f&&/^  host:/{print $2; exit}' postal.yml)
if [ -z "$WEB_HOST" ]; then
    WEB_HOST=$(awk -F': *' '/^postal:/{f=1;next} f&&/^  web_hostname:/{print $2; exit}' postal.yml)
fi
echo "  $WEB_HOST"

echo ""
echo "DNS SMTP hostname:"
SMTP_HOST=$(awk -F': *' '/^dns:/{f=1;next} f&&/^  smtp_server_hostname:/{print $2; exit}' postal.yml)
echo "  ${SMTP_HOST:-'Not set'}"

echo ""
echo "Derived base domain:"
DERIVED_BASE=$(echo "$WEB_HOST" | awk -F. '{ if (NF>=2) print $(NF-1)"."$NF; else print $0 }')
echo "  $DERIVED_BASE"

echo ""
echo "🧪 TESTING HOSTNAME EXTRACTION LOGIC:"
echo "====================================="

# Test the exact logic used in the script
CURRENT_HOSTNAME=$(awk -F': *' '/^web:/{f=1;next} f&&/^  host:/{print $2; exit}' postal.yml)
if [ -z "$CURRENT_HOSTNAME" ]; then
    CURRENT_HOSTNAME=$(awk -F': *' '/^postal:/{f=1;next} f&&/^  web_hostname:/{print $2; exit}' postal.yml)
fi
[ -z "$CURRENT_HOSTNAME" ] && CURRENT_HOSTNAME="postal.soham.top"

echo "Script would use hostname: $CURRENT_HOSTNAME"

echo ""
echo "✅ Configuration reading test complete!"
echo ""
echo "📝 The script will now:"
echo "• Look for users: admin@$CURRENT_HOSTNAME, user@$CURRENT_HOSTNAME"
echo "• Look for domains/servers: $CURRENT_HOSTNAME"
echo "• Update them to use: $DERIVED_BASE (if different)"

if [ "$CURRENT_HOSTNAME" = "$DERIVED_BASE" ]; then
    echo ""
    echo "ℹ️  Current hostname matches derived base domain - no updates needed"
else
    echo ""
    echo "⚠️  Current hostname differs from base domain - updates would be made"
fi
