# Postal SPF Configuration Fix Documentation

## Overview
This document details the fix for the Postal mail server SPF configuration issue where the web interface was showing `spf.postal.example.com` instead of the correct domain `spf.postal.soham.top`.

## Issue Description

### Problem
- Postal web interface displayed SPF validation messages with `spf.postal.example.com`
- Domain validation errors showed: "An SPF record exists but it doesn't include spf.postal.example.com"
- This occurred despite having a correct `postal.yml` configuration file

### Root Cause Analysis
1. **Configuration File Sync Issue**: The `postal.yml` file in the container was different from the host file
2. **Default Configuration Override**: Postal was loading default example.com settings instead of custom configuration
3. **Volume Mount Problem**: The container had an outdated version of postal.yml that lacked the DNS section

## Solution Implemented

### Step 1: Identified Configuration Loading Issue
```bash
# Checked Postal's loaded configuration
sudo docker compose -f docker-compose.prod.yml exec -T web rails runner -
# Found that config showed: spf_include="spf.postal.example.com"
# Instead of expected: spf_include="spf.postal.soham.top"
```

### Step 2: Verified File Synchronization Problem
```bash
# Compared host file vs container file
cat postal.yml  # (host - correct config)
sudo docker compose -f docker-compose.prod.yml exec web cat /config/postal.yml  # (container - old config)
```

### Step 3: Fixed Configuration Sync
```bash
# Copied correct configuration to container
sudo docker cp postal.yml $(sudo docker compose -f docker-compose.prod.yml ps -q web):/config/postal.yml

# Restarted all services to load new configuration
sudo docker compose -f docker-compose.prod.yml restart
```

### Step 4: Cleared Domain Cache
```bash
# Forced re-validation of domains with new configuration
sudo docker compose -f docker-compose.prod.yml exec -T web rails runner -
# Cleared dns_checked_at, spf_status, spf_error fields
# Triggered domain.check_dns for all domains
```

## Configuration Files

### postal.yml (Correct Configuration)
```yaml
version: 2

postal:
  smtp_hostname: smtp
  web_hostname: postal.soham.top
  web_protocol: https

# ... other sections ...

dns:
  mx_records:
    - mx.postal.soham.top
  smtp_server_hostname: postal.soham.top
  spf_include: spf.postal.soham.top
  return_path_domain: rp.postal.soham.top
  custom_return_path_prefix: psrp
  route_domain: routes.postal.soham.top
  track_domain: track.postal.soham.top
```

### docker-compose.prod.yml (Volume Mount)
```yaml
services:
  web:
    image: psschand16/postal-arm64:latest
    volumes:
      - ./postal.yml:/config/postal.yml  # This mount ensures persistence
```

## Verification Steps

### 1. Configuration Loading Test
```bash
cd /home/ubuntu/ms/postal
sudo docker compose -f docker-compose.prod.yml exec -T web rails runner - <<'RUBY'
config = Postal::Config
puts "SPF include: #{config.dns.spf_include}"
RUBY
# Expected output: SPF include: spf.postal.soham.top
```

### 2. Domain Validation Test
```bash
# Check domain validation messages
sudo docker compose -f docker-compose.prod.yml exec -T web rails runner - <<'RUBY'
Domain.all.each do |domain|
  puts "Domain: #{domain.name}"
  puts "SPF Error: #{domain.spf_error}" if domain.spf_error.present?
end
RUBY
# Expected: SPF errors should reference spf.postal.soham.top
```

### 3. Restart Persistence Test
```bash
# Full restart test
sudo docker compose -f docker-compose.prod.yml down
sudo docker compose -f docker-compose.prod.yml up -d
# Configuration should persist after restart
```

## Automation Tools Created

### 1. Configuration Sync Script
File: `/home/ubuntu/ms/postal/sync-postal-config.sh`
- Ensures postal.yml synchronization between host and container
- Verifies configuration loading
- Clears domain cache after changes
- Provides automated fix for future issues

### 2. Enhanced Setup Script
File: `/home/ubuntu/ms/postal/postal-setup-complete.sh`
- Added option 8: "Sync Configuration and Restart Services"
- Includes automated SPF hostname fixes
- Handles configuration persistence issues

## Prevention Measures

### 1. Regular Configuration Verification
```bash
# Use the sync script regularly
cd /home/ubuntu/ms/postal
./sync-postal-config.sh
```

### 2. Post-Restart Checks
```bash
# After any restart, verify configuration
cd /home/ubuntu/ms/postal
./postal-setup-complete.sh
# Choose option 8 to sync configuration
```

### 3. Backup Strategy
- Configuration backups are automatically created in `config-backups/`
- Working configuration snapshot: `config-backups/working-postal-spf-fix-20250929_172604/`

## Technical Details

### Database Changes
The fix also included updating existing domain records that had cached the old SPF hostname:
```sql
-- Domains table updates
UPDATE domains SET spf_error = REPLACE(spf_error, 'spf.postal.example.com', 'spf.postal.soham.top');
UPDATE domains SET dns_checked_at = NULL; -- Force re-validation
```

### Configuration Loading Order
1. Docker container starts
2. Volume mount provides postal.yml from host
3. Postal application reads /config/postal.yml
4. DNS configuration loaded into Postal::Config
5. Domain validation uses loaded DNS settings

## Testing Results

### Before Fix
- Configuration: `spf_include="spf.postal.example.com"`
- Domain validation: "An SPF record exists but it doesn't include spf.postal.example.com"
- Persistence: ❌ Configuration reverted after restart

### After Fix
- Configuration: `spf_include="spf.postal.soham.top"`
- Domain validation: "An SPF record exists but it doesn't include spf.postal.soham.top"
- Persistence: ✅ Configuration persists across restarts

## Future Maintenance

### Regular Checks
1. Monthly verification of configuration sync
2. Post-update configuration validation
3. Backup verification before major changes

### Troubleshooting
If SPF configuration issues reoccur:
1. Run `./sync-postal-config.sh`
2. Check volume mount in docker-compose.yml
3. Verify postal.yml DNS section is complete
4. Use postal-setup-complete.sh option 8

## Related Files
- `/home/ubuntu/ms/postal/postal.yml` - Main configuration
- `/home/ubuntu/ms/postal/docker-compose.prod.yml` - Container orchestration
- `/home/ubuntu/ms/postal/sync-postal-config.sh` - Configuration sync tool
- `/home/ubuntu/ms/postal/postal-setup-complete.sh` - Enhanced setup script
- `/home/ubuntu/ms/config-backups/working-postal-spf-fix-20250929_172604/` - Working configuration backup

## Resolution Date
September 29, 2025 - Issue fully resolved with persistent configuration and automation tools in place.
