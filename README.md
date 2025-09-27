# 📧 Mail Server Integration

> **Production-ready mail server solution combining Mailu and Postal with shared database infrastructure**

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://docker.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)](https://github.com)

A comprehensive mail server integration that combines **Mailu** (administration & webmail), **Postal** (transactional emails), and **Mautic** (marketing automation) with automated setup tools and shared MySQL database infrastructure.

## 🚀 **Quick Start**

```bash
# 1. Clone and setup
git clone <your-repo-url> mail-server
cd mail-server

# 2. Verify project structure
./verify-project.sh

# 3. Configure (copy templates and update <CHANGE_THIS> values)
cp mailu/mailu.env.template mailu/mailu.env
cp postal/postal.yml.template postal/postal.yml
cp postal/docker-compose.prod.yml.template postal/docker-compose.prod.yml

# 4. Deploy core services
cd mailu && docker compose up -d
cd ../postal && docker compose -f docker-compose.prod.yml up -d

# 5. Setup Postal (optional)
./postal/postal-setup-complete.sh full yourdomain.com admin@yourdomain.com

# 6. Add Mautic marketing automation (optional)
cd mautic && ./setup-mautic.sh --with-proxy --domain mautic.yourdomain.com
```

## 📁 **Project Structure**

```
mail-server-integration/
├── 📖 SETUP.md                            # Complete setup guide
├── 🔧 MIGRATION-SCRIPTS-GUIDE.md          # Database migration docs
├── 🚀 migrate-mail-databases.sh           # Interactive migration tool
├── ↩️  rollback-mail-databases.sh         # Rollback/recovery tool
├── 📮 mailu/                              # Mailu mail server
│   ├── docker-compose.yml               #   Service definitions
│   ├── mailu.env.template                #   Environment template
│   └── postal.conf                       #   Nginx proxy config
├── 📬 postal/                             # Postal mail server  
│   ├── docker-compose.prod.yml.template  #   Production template
│   ├── postal.yml.template               #   Config template
│   └── postal-setup-complete.sh          #   Automated setup
└── 📧 mautic/                             # Marketing automation
    ├── docker-compose.yml.template       #   Mautic services
    ├── setup-mautic.sh                   #   Automated setup
    └── README.md                          #   Mautic documentation
```

## 🚀 Quick Start

### 1. **Main Setup Guide**
Start here for complete integration setup:
```bash
cat README-POSTAL-NGINX-INTEGRATION.md
```

### 2. **Database Migration**
Use when changing MySQL connection strings:
```bash
./migrate-mail-databases.sh
```

### 3. **Recovery/Rollback**
Use if migration fails or needs rollback:
```bash
./rollback-mail-databases.sh
```

## 📚 Documentation Guide

| Document | Purpose | When to Use |
|----------|---------|-------------|
| `README-POSTAL-NGINX-INTEGRATION.md` | Complete setup guide | Initial setup, troubleshooting, reference |
| `MIGRATION-SCRIPTS-GUIDE.md` | Database migration docs | Database server changes, credential updates |

## 🎯 Features Implemented

### ✅ **Infrastructure Integration**
- Nginx reverse proxy for postal.soham.top subdomain
- Shared SSL certificates between services
- Network connectivity between mail servers
- Persistent configuration across restarts

### ✅ **Database Integration**
- Shared MySQL database instance (postal-db-1)
- Mailu migrated from SQLite to MySQL
- Automated backup and migration tools
- Production-ready data persistence

### ✅ **Security & Reliability**
- Rails CSRF protection for Postal
- SSL/TLS configuration with CloudFlare support
- Automated rollback capabilities
- Configuration backup system

### ✅ **Automation Tools**
- Interactive migration scripts
- Health verification systems
- Service restart coordination
- Error handling and recovery

## 🌐 **Service Endpoints**

- **Mailu Admin**: https://mail.soham.top/admin/
- **Mailu Webmail**: https://mail.soham.top/webmail/ 
- **Postal Interface**: https://postal.soham.top/
- **Mautic Marketing**: https://mautic.soham.top/

## 🗄️ Database Structure

```
MySQL Container: postal-db-1 (Shared Database)
├── postal              # Postal main database
├── mailu               # Mailu user/domain data
├── mautic              # Mautic marketing automation
└── postal-server-*     # Postal message databases
```

## 📞 Support & Troubleshooting

1. **Check main documentation**: `README-POSTAL-NGINX-INTEGRATION.md`
2. **Database issues**: `MIGRATION-SCRIPTS-GUIDE.md` 
3. **Service logs**: `docker logs [container-name]`
4. **Rollback if needed**: `./rollback-mail-databases.sh`

## 🔄 Maintenance Tasks

### Regular Maintenance
- Monitor disk usage for database growth
- Review log files for errors
- Test backup/restore procedures
- Update credentials periodically

### Database Maintenance
```bash
# Check database sizes
docker exec postal-db-1 mysql -u root -ppostal_root_password -e "SELECT table_schema, ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'DB Size in MB' FROM information_schema.tables GROUP BY table_schema;"

# Run migration script for updates
./migrate-mail-databases.sh
```

---

**Version**: 1.0  
**Last Updated**: September 2025  
**Status**: Production Ready ✅  

This integration provides a robust, scalable mail server solution with comprehensive documentation and automated management tools.
