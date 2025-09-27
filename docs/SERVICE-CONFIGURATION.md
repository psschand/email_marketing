# Complete Mail Server Infrastructure - Service Configuration

## Service Overview

This document provides detailed configuration information for all services in the mail server infrastructure.

## 🗄️ Database Configuration

### MySQL Container: postal-db-1
- **Image**: mysql:8.0
- **Root Password**: postal_root_password
- **Port**: 3306
- **Networks**: postal_default, mailu_default

### Database Users and Permissions

| Service | Database | Username | Password | Permissions |
|---------|----------|----------|----------|-------------|
| Mailu | mailu | mailu | mailu_secure_password_123 | ALL on mailu.* |
| Postal | postal | postal | postal_password | ALL on postal.* |
| Mautic | mautic | mautic | mautic_secure_password_123 | ALL on mautic.* |

## 🌐 Service Endpoints

### Mailu (Traditional Email)
- **URL**: https://mail.soham.top/
- **Admin**: admin@soham.top / Soham@1234
- **Container**: mailu-front-1
- **Services**: admin, webmail, smtp, imap, antispam

### Postal (Transactional Email)
- **URL**: https://postal.soham.top/
- **Container**: postal-web-1
- **Port**: 5000
- **Rails Environment**: production

### Mautic (Marketing Automation)
- **URL**: https://mautic.soham.top/
- **Container**: mautic-web-1
- **Port**: 80
- **Database**: Shared with other services

## 🔐 SSL Certificate Configuration

### Let's Encrypt Wildcard Certificate
- **Domain**: *.soham.top
- **Renewal**: Automatic via CloudFlare DNS challenge
- **Location**: /mailu/certs/wildcard-*
- **Validity**: 90 days (auto-renews at 30 days)

### CloudFlare Integration
- **API Token**: Configured in /etc/letsencrypt/cloudflare.ini
- **SSL Mode**: Full (strict)
- **Challenge**: DNS-01

## 🔧 Nginx Configuration

### Proxy Configuration
All services are proxied through the Mailu nginx container (mailu-front-1):

```nginx
# Mailu Admin (mail.soham.top)
server_name mail.soham.top;
proxy_pass http://admin:8080;

# Postal (postal.soham.top) 
server_name postal.soham.top;
proxy_pass http://postal-web-1:5000;

# Mautic (mautic.soham.top)
server_name mautic.soham.top;
proxy_pass http://mautic-web-1:80;
```

### Key Configuration Files
- Main config: `/etc/nginx/nginx.conf` (in mailu-front-1)
- Proxy configs: `/etc/nginx/conf.d/*.conf`
- Backup: `config-backups/nginx/working-nginx.conf`

## 🔄 Docker Networks

### Network Architecture
```
mailu_default ←→ postal_default
     ↓               ↓
  Mailu Services   Postal Services
                       ↓
                   Mautic Services
```

### Shared Resources
- Database container accessible from all networks
- Certificate directory mounted across services
- Nginx proxy handling all external traffic

## 📊 Monitoring and Logs

### Health Check Commands
```bash
# Check all services
docker ps --format "table {{.Names}}\t{{.Status}}"

# Database connection test
./recreate-db-users.sh

# SSL certificate check
openssl x509 -in /mailu/certs/wildcard-fullchain.pem -noout -dates
```

### Log Locations
```bash
# Service logs
docker logs mailu-admin-1
docker logs postal-web-1  
docker logs mautic-web-1
docker logs postal-db-1

# Nginx logs
docker exec mailu-front-1 tail -f /var/log/nginx/error.log
```

## 🛠️ Maintenance Tasks

### Daily Tasks
- Monitor service health
- Check log files for errors
- Verify SSL certificate validity

### Weekly Tasks  
- Run database backup: `./backup-databases.sh`
- Update service containers
- Review security logs

### Monthly Tasks
- Certificate renewal check
- Performance optimization
- Security updates

## 🚨 Emergency Procedures

### Service Failure Recovery
1. Check service status: `docker ps`
2. Restart failed service: `docker compose restart <service>`
3. Check logs: `docker logs <container>`
4. Apply fixes and restart

### Database Recovery
1. Stop all services
2. Restore from backup: `restore-databases.sh`
3. Recreate users: `./recreate-db-users.sh`
4. Restart services: `./start-all-services.sh`

### Certificate Emergency
1. Check certificate: `openssl x509 -in /mailu/certs/wildcard-fullchain.pem -noout -dates`
2. Force renewal: `./renew-certificates.sh`
3. Restart nginx: `docker exec mailu-front-1 nginx -s reload`

---

**Configuration Version**: 1.0.0  
**Last Updated**: September 2025
