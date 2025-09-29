#!/bin/bash

# =============================================================================
# CONFIG BACKUP SCRIPT
# =============================================================================
# Creates timestamped backups of all working mail server configurations
# =============================================================================

BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/home/ubuntu/ms/config-backups/backup_${BACKUP_DATE}"

echo "🗂️ CREATING CONFIGURATION BACKUP"
echo "================================="
echo "Backup Directory: $BACKUP_DIR"
echo ""

# Create timestamped backup directory
mkdir -p "$BACKUP_DIR"

echo "📁 Backing up configuration files..."

# Mailu configurations
cp /home/ubuntu/ms/mailu/postal.conf "$BACKUP_DIR/postal.conf"
cp /home/ubuntu/ms/mailu/mautic.conf "$BACKUP_DIR/mautic.conf"
cp /home/ubuntu/ms/mailu/docker-compose.yml "$BACKUP_DIR/mailu-docker-compose.yml"
cp /home/ubuntu/ms/mailu/mailu.env "$BACKUP_DIR/mailu.env"

# Postal configurations
cp /home/ubuntu/ms/postal/docker-compose.yml "$BACKUP_DIR/postal-docker-compose.yml"
cp /home/ubuntu/ms/postal/postal.yml "$BACKUP_DIR/postal-config.yml"

# Mautic configurations
cp /home/ubuntu/ms/docker-compose.mautic.yml "$BACKUP_DIR/mautic-docker-compose.yml"

# Management scripts
cp /home/ubuntu/ms/all-mail-admin-credentials.sh "$BACKUP_DIR/admin-credentials.sh"
cp /home/ubuntu/ms/test-postal-csrf.sh "$BACKUP_DIR/test-postal-csrf.sh"
cp /home/ubuntu/ms/postal-credentials-discovery.sh "$BACKUP_DIR/postal-credentials-discovery.sh"

echo "✅ Configuration files backed up successfully!"
echo ""

echo "📋 BACKUP CONTENTS:"
echo "==================="
ls -la "$BACKUP_DIR"

echo ""
echo "🔧 CURRENT SERVICE STATUS:"
echo "=========================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(mailu|postal|mautic|mysql)"

echo ""
echo "🌐 CURRENT ENDPOINTS:"
echo "===================="
echo "• Mailu Admin: https://mail.soham.top/admin"
echo "• Postal Admin: https://postal.soham.top"
echo "• Mautic Admin: https://mautic.soham.top"

echo ""
echo "✨ BACKUP COMPLETE: $BACKUP_DIR"
