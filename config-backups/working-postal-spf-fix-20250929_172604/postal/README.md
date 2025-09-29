# POSTAL Configuration & Setup

This folder contains the Postal mail server configuration and setup tools.

## 🚀 Quick Setup

Use the consolidated setup script for all Postal operations:

```bash
# Complete setup (all steps)
./postal-setup-complete.sh full example.com admin@example.com

# Individual steps
./postal-setup-complete.sh init          # Initial server setup
./postal-setup-complete.sh users         # Create default users  
./postal-setup-complete.sh domain soham.top test@gmail.com  # Domain + test
```

## 📁 Files Overview

- `postal-setup-complete.sh` - **Main setup script** (replaces 3 separate scripts)
- `docker-compose.prod.yml` - Production Docker configuration
- `postal.yml` - Postal application configuration  
- `README.md` - This documentation

## ⚙️ Configuration Notes

### POSTAL_EXTRA_HOSTS
- **Purpose**: Comma-separated list of additional hostnames Postal will accept in Host header
- **Example**: `POSTAL_EXTRA_HOSTS="postal.soham.top,alias.example.org"`
- **Use case**: When reverse proxy (Mailu front) forwards requests to Postal backend
- **Security**: Only add hostnames you control

### POSTAL_ALLOW_ANY_HOST  
- **Purpose**: When `true`, disables Rails host header checks (accepts any Host)
- **Use case**: Temporary debugging or development behind trusted reverse proxy
- **Security**: ⚠️ **Dangerous in production** - enables Host header attacks

## 🔧 Quick Commands

### Service Management
```bash
# Start services
docker compose -f docker-compose.prod.yml up -d

# Restart web container after config changes
docker compose -f docker-compose.prod.yml up -d --no-deps --force-recreate web

# Check environment variables
docker compose -f docker-compose.prod.yml exec -T web env | grep -E 'POSTAL_ALLOW_ANY_HOST|POSTAL_EXTRA_HOSTS'
```

### Setup Commands
```bash
# View all setup options
./postal-setup-complete.sh help

# Initial server setup only
./postal-setup-complete.sh init

# Create default users (admin@postal.example.com / changeme)
./postal-setup-complete.sh users

# Setup domain and send test email
./postal-setup-complete.sh domain yourdomain.com recipient@email.com
```

## 🚨 Security Best Practices

1. **Prefer explicit hostnames**: Use `POSTAL_EXTRA_HOSTS` instead of `POSTAL_ALLOW_ANY_HOST=true`
2. **Temporary debugging only**: If using `POSTAL_ALLOW_ANY_HOST=true`, revert to `false` afterward
3. **Change default passwords**: Update default user passwords after initial setup
4. **Host header validation**: Never leave `POSTAL_ALLOW_ANY_HOST=true` in production

## 📝 Migration Notes

This setup script consolidates the functionality of these previous scripts:
- ~~setup-new-postal-server.sh~~ → `postal-setup-complete.sh init`
- ~~create-default-user.sh~~ → `postal-setup-complete.sh users`  
- ~~setup-and-send-v2.sh~~ → `postal-setup-complete.sh domain`

---

**Quick Start Command**: `cd /home/ubuntu/ms/postal && docker compose -f docker-compose.prod.yml up -d`
