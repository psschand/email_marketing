# Postal SPF Configuration Fix - Quick Reference

## Problem
Postal web interface showing wrong SPF hostname: `spf.postal.example.com` instead of `spf.postal.soham.top`

## Quick Fix
```bash
cd /home/ubuntu/ms/postal
./sync-postal-config.sh
```

## Manual Fix Steps
```bash
# 1. Sync configuration
cd /home/ubuntu/ms/postal
sudo docker compose -f docker-compose.prod.yml down
sudo docker compose -f docker-compose.prod.yml up -d

# 2. Clear domain cache
sudo docker compose -f docker-compose.prod.yml exec -T web rails runner - <<'RUBY'
Domain.all.each do |domain|
  domain.update!(dns_checked_at: nil, spf_status: nil, spf_error: nil)
  domain.check_dns if domain.respond_to?(:check_dns)
end
RUBY
```

## Verification
```bash
# Check loaded configuration
sudo docker compose -f docker-compose.prod.yml exec -T web rails runner - <<'RUBY'
puts "SPF: #{Postal::Config.dns.spf_include}"
RUBY
# Should output: SPF: spf.postal.soham.top
```

## Backup Location
Working configuration saved in: `/home/ubuntu/ms/config-backups/working-postal-spf-fix-20250929_172604/`

## Prevention
- Use `./sync-postal-config.sh` after any configuration changes
- Use postal-setup-complete.sh option 8 for automated sync
- Verify configuration after container restarts
