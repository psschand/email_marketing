#!/bin/bash

# =============================================================================
# Working Configuration Backup Verification Script
# =============================================================================
# This script verifies the integrity and completeness of the backup
# Created: September 29, 2025
# Backup: working-postal-spf-fix-20250929_172604
# =============================================================================

BACKUP_DIR="/home/ubuntu/ms/config-backups/working-postal-spf-fix-20250929_172604"

echo "==============================================="
echo "BACKUP VERIFICATION REPORT"
echo "==============================================="
echo "Backup Directory: $BACKUP_DIR"
echo "Created: $(date)"
echo ""

# Verify critical files exist
echo "--- Critical Files Check ---"

critical_files=(
    "postal/postal.yml"
    "postal/docker-compose.prod.yml"
    "postal/postal-setup-complete.sh"
    "postal/sync-postal-config.sh"
    "mailu/docker-compose.yml"
    "mailu/mailu.env"
    "POSTAL-SPF-FIX-DOCUMENTATION.md"
)

for file in "${critical_files[@]}"; do
    if [ -f "$BACKUP_DIR/$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - MISSING"
    fi
done

echo ""
echo "--- Configuration Verification ---"

# Check postal.yml has correct SPF configuration
if [ -f "$BACKUP_DIR/postal/postal.yml" ]; then
    SPF_INCLUDE=$(grep "spf_include:" "$BACKUP_DIR/postal/postal.yml" | awk '{print $2}')
    if [ "$SPF_INCLUDE" = "spf.postal.soham.top" ]; then
        echo "✅ postal.yml contains correct SPF configuration: $SPF_INCLUDE"
    else
        echo "❌ postal.yml SPF configuration issue: $SPF_INCLUDE"
    fi
else
    echo "❌ postal.yml not found in backup"
fi

# Check docker-compose has volume mount
if [ -f "$BACKUP_DIR/postal/docker-compose.prod.yml" ]; then
    if grep -q "./postal.yml:/config/postal.yml" "$BACKUP_DIR/postal/docker-compose.prod.yml"; then
        echo "✅ docker-compose.yml has correct volume mount"
    else
        echo "❌ docker-compose.yml volume mount issue"
    fi
else
    echo "❌ docker-compose.prod.yml not found in backup"
fi

echo ""
echo "--- Backup Statistics ---"
TOTAL_FILES=$(find "$BACKUP_DIR" -type f | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo "Total Files: $TOTAL_FILES"
echo "Total Size: $TOTAL_SIZE"

echo ""
echo "--- Key Configuration Summary ---"
echo "SPF Hostname: spf.postal.soham.top"
echo "Web Hostname: postal.soham.top"
echo "Return Path: rp.postal.soham.top"
echo "MX Records: mx.postal.soham.top"

echo ""
echo "--- Restoration Instructions ---"
echo "To restore this configuration:"
echo "1. cd /home/ubuntu/ms"
echo "2. cp -r $BACKUP_DIR/postal/* postal/"
echo "3. cp -r $BACKUP_DIR/mailu/* mailu/"
echo "4. cd postal && ./sync-postal-config.sh"

echo ""
echo "==============================================="
echo "BACKUP VERIFICATION COMPLETE"
echo "==============================================="
