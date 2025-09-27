# Complete Mail Server Infrastructure Project

## 🚀 Overview

This is a complete, production-ready mail server infrastructure featuring three integrated services:

- **Mailu**: Traditional email server with webmail (mail.soham.top)
- **Postal**: Transactional email service (postal.soham.top) 
- **Mautic**: Marketing automation platform (mautic.soham.top)

All services share a single MySQL database cluster and use wildcard SSL certificates.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Mailu       │    │     Postal      │    │     Mautic      │
│  mail.soham.top │    │ postal.soham.top│    │ mautic.soham.top│
│     Port 443    │    │     Port 443    │    │     Port 443    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      MySQL 8.0 Cluster   │
                    │     (postal-db-1)        │
                    │  - mailu database        │
                    │  - postal database       │
                    │  - mautic database       │
                    └───────────────────────────┘
```

## 📋 Quick Start

### 1. Prerequisites
- Docker & Docker Compose installed
- CloudFlare account with DNS management
- Domain configured (soham.top with subdomains)

### 2. Launch Services
```bash
# Start all services
./start-all-services.sh

# Or start individually:
cd mailu && docker compose up -d
cd ../postal && docker compose up -d  
cd ../mautic && docker compose up -d
```

### 3. Access Points
- **Mailu Admin**: https://mail.soham.top/ (admin@soham.top / Soham@1234)
- **Postal**: https://postal.soham.top/
- **Mautic**: https://mautic.soham.top/

## 🔧 Configuration

### Database Architecture
- **MySQL Container**: `postal-db-1`
- **Databases**: `mailu`, `postal`, `mautic`  
- **Users**: Each service has dedicated database user
- **Networking**: Services communicate via Docker networks

### SSL Certificates
- **Type**: Let's Encrypt wildcard certificates (*.soham.top)
- **Renewal**: Automatic via CloudFlare DNS challenge
- **Location**: `/mailu/certs/wildcard-*`

### Environment Variables
Key configuration files:
- `mailu/mailu.env` - Mailu configuration
- `postal/postal.yml` - Postal configuration  
- `docker-compose.mautic.yml` - Mautic configuration

## 🛠️ Maintenance

### Backup Database
```bash
./backup-databases.sh
```

### Update SSL Certificates
```bash
./renew-certificates.sh
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker logs mailu-admin-1 -f
```

## 🔐 Security

### Database Security
- Separate database users per service
- Strong passwords for all accounts
- Network isolation between services

### SSL/TLS Security
- TLS 1.2+ only
- Strong cipher suites
- HSTS headers enabled
- CloudFlare Full (strict) mode

### Access Control
- Admin interfaces behind authentication
- Rate limiting enabled
- Firewall rules configured

## 📁 Project Structure

```
ms/
├── PROJECT-README.md          # This file
├── start-all-services.sh      # Start all services
├── backup-databases.sh        # Database backup script
├── renew-certificates.sh      # Certificate renewal
├── config-backups/           # Configuration backups
│   ├── nginx/               # Nginx configurations
│   └── certs/               # Certificate backups
├── mailu/                   # Mailu mail server
│   ├── docker-compose.yml   # Mailu services
│   ├── mailu.env           # Mailu configuration
│   └── *.conf              # Nginx proxy configs
├── postal/                  # Postal transactional mail
│   ├── docker-compose.yml   # Postal services
│   └── postal.yml          # Postal configuration
├── mautic/                  # Mautic marketing automation
│   └── setup-mautic.sh     # Mautic setup script
└── docker-compose.mautic.yml # Mautic services
```

## 🚨 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   ```bash
   # Check database status
   docker exec postal-db-1 mysql -u root -ppostal_root_password -e "SHOW DATABASES;"
   
   # Recreate user if needed
   ./recreate-db-users.sh
   ```

2. **SSL Certificate Issues**
   ```bash
   # Check certificate validity
   openssl x509 -in /mailu/certs/wildcard-fullchain.pem -noout -dates
   
   # Renew certificates
   ./renew-certificates.sh
   ```

3. **Service Not Responding**
   ```bash
   # Restart specific service
   cd mailu && docker compose restart
   
   # Check service logs
   docker logs service-name-1 --tail=50
   ```

### Log Locations
- **Mailu**: `docker logs mailu-admin-1`
- **Postal**: `docker logs postal-web-1`
- **Mautic**: `docker logs mautic-web-1`
- **Database**: `docker logs postal-db-1`

## 📞 Support

### Key Commands
```bash
# Check all service status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Database health check
./verify-project.sh

# Full system restart
./restart-all-services.sh
```

### Configuration Files
- Database credentials: Check respective `.env` files
- SSL certificates: `/mailu/certs/`
- Nginx configs: Backed up in `config-backups/nginx/`

## 🎯 Production Checklist

- [x] SSL certificates configured and auto-renewing
- [x] Database backups automated  
- [x] All services using dedicated database users
- [x] Nginx configurations persistent
- [x] Security headers implemented
- [x] CloudFlare protection enabled
- [x] Admin accounts created with strong passwords
- [x] Documentation complete

---

**Last Updated**: September 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅
