#!/bin/bash

# DNS Record Checker for Postal Mail Server
# This script helps verify that your DNS records are correctly configured

DOMAIN="soham.top"
POSTAL_HOSTNAME="postal.soham.top"

echo "==============================================="
echo "DNS Records Check for $DOMAIN"
echo "==============================================="

# Install dig if not available
if ! command -v dig &> /dev/null; then
    echo "Installing dig utility..."
    sudo apt update && sudo apt install -y dnsutils
fi

echo -e "\n--- SPF Record Check ---"
echo "Looking for SPF record in $DOMAIN..."
SPF_RECORD=$(dig TXT $DOMAIN +short | grep -i spf | tr -d '"')
if [ -n "$SPF_RECORD" ]; then
    echo "Current SPF record: $SPF_RECORD"
    if echo "$SPF_RECORD" | grep -q "spf.postal.example.com"; then
        echo "❌ ISSUE FOUND: SPF record still contains 'spf.postal.example.com'"
        echo "✅ SHOULD BE: v=spf1 a mx include:spf.postal.soham.top ~all"
    elif echo "$SPF_RECORD" | grep -q "spf.postal.soham.top"; then
        echo "✅ SPF record looks correct!"
    else
        echo "⚠️  SPF record doesn't contain expected postal hostname"
    fi
else
    echo "❌ No SPF record found for $DOMAIN"
fi

echo -e "\n--- MX Record Check ---"
echo "Looking for MX records..."
MX_RECORDS=$(dig MX $DOMAIN +short)
if [ -n "$MX_RECORDS" ]; then
    echo "MX records found:"
    echo "$MX_RECORDS"
else
    echo "❌ No MX records found"
fi

echo -e "\n--- A Record Check for Postal ---"
echo "Checking if $POSTAL_HOSTNAME resolves..."
A_RECORD=$(dig A $POSTAL_HOSTNAME +short)
if [ -n "$A_RECORD" ]; then
    echo "✅ $POSTAL_HOSTNAME resolves to: $A_RECORD"
else
    echo "❌ $POSTAL_HOSTNAME does not resolve"
fi

echo -e "\n--- DKIM Record Check ---"
echo "Note: DKIM records are created automatically by Postal"
echo "Check your Postal web interface for the specific DKIM record to add"

echo -e "\n--- Return Path Check ---"
echo "Looking for return path records..."
RP_RECORD=$(dig TXT psrp.$DOMAIN +short)
if [ -n "$RP_RECORD" ]; then
    echo "Return path record found: $RP_RECORD"
else
    echo "❌ No return path record found for psrp.$DOMAIN"
fi

echo -e "\n==============================================="
echo "DNS Records Summary"
echo "==============================================="
echo "To fix the SPF issue, update your DNS SPF record from:"
echo "  v=spf1 a mx include:spf.postal.example.com ~all"
echo "To:"
echo "  v=spf1 a mx include:spf.postal.soham.top ~all"
echo ""
echo "This change must be made at your DNS provider (registrar/hosting provider)."
echo "==============================================="
