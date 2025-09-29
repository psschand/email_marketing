# Configuration Backups Index

## Backup Directory Structure
All backups are stored in `/home/ubuntu/ms/config-backups/`

## Backup History

### working-postal-spf-fix-20250929_172604
- **Date**: September 29, 2025 17:26:04 UTC
- **Purpose**: Working configuration after Postal SPF hostname fix
- **Issue Resolved**: Postal showing spf.postal.example.com instead of spf.postal.soham.top
- **Status**: ✅ VERIFIED WORKING
- **Size**: 396K (70 files)
- **Critical Files**:
  - postal/postal.yml (correct SPF configuration)
  - postal/docker-compose.prod.yml (volume mounts)
  - postal/sync-postal-config.sh (automation tool)
  - postal/postal-setup-complete.sh (enhanced setup)
  - POSTAL-SPF-FIX-DOCUMENTATION.md (complete fix documentation)

### Verification Commands
```bash
# Verify any backup
/home/ubuntu/ms/config-backups/working-postal-spf-fix-20250929_172604/verify-backup.sh

# Restore from backup
cd /home/ubuntu/ms
cp -r config-backups/working-postal-spf-fix-20250929_172604/postal/* postal/
cp -r config-backups/working-postal-spf-fix-20250929_172604/mailu/* mailu/
cd postal && ./sync-postal-config.sh
```

## Backup Best Practices

### When to Create Backups
- ✅ Before major configuration changes
- ✅ After resolving critical issues
- ✅ Before system updates
- ✅ After successful feature implementations

### Backup Naming Convention
Format: `{purpose}-{YYYYMMDD_HHMMSS}`
Examples:
- `working-postal-spf-fix-20250929_172604`
- `pre-update-20251001_120000`
- `feature-mautic-integration-20251015_140000`

### What to Include in Backups
- All configuration files (yml, env, conf)
- Management scripts (sh files)
- Documentation (md files)
- Log files (for troubleshooting context)
- Database schemas (if applicable)

### Backup Verification
Each backup should include:
- verify-backup.sh script
- Documentation of changes made
- Restoration instructions
- Test commands to verify functionality

## Restoration Process

### Full Restoration
1. Stop all services
2. Copy backup files to appropriate locations
3. Run sync scripts to ensure proper configuration
4. Start services and verify functionality

### Partial Restoration
1. Identify specific files/configurations needed
2. Copy only required files
3. Run appropriate sync/restart commands
4. Verify specific functionality restored

## Monitoring

### Regular Checks
- Monthly backup verification
- Quarterly backup cleanup (keep last 12 months)
- Annual backup strategy review

### Backup Health
- Verify backup integrity monthly
- Test restoration process quarterly
- Document any issues or improvements needed
