# 🚀 Mail Server Integration Project

A complete production-ready mail server solution combining **Mailu** and **Postal** with shared MySQL database, automated migration tools, and nginx reverse proxy integration.

## 📋 **Quick Start**

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd mail-server-integration

# 2. Copy and configure environment files
cp mailu/mailu.env.template mailu/mailu.env
cp postal/postal.yml.template postal/postal.yml  
cp postal/docker-compose.prod.yml.template postal/docker-compose.prod.yml

# 3. Update all <CHANGE_THIS> placeholders in the files above

# 4. Start the services
cd mailu && docker compose up -d
cd ../postal && docker compose -f docker-compose.prod.yml up -d

# 5. Run setup (optional)
./postal/postal-setup-complete.sh full yourdomain.com admin@yourdomain.com
```

## 🏗️ **Architecture**

```
┌─────────────────┐    ┌─────────────────┐
│   Mailu Stack   │    │  Postal Stack   │
│                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │    nginx    │ │    │ │  Rails Web  │ │
│ │   (front)   │ │    │ │     App     │ │
│ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   webmail   │ │    │ │ SMTP Server │ │
│ │   dovecot   │ │    │ │   Worker    │ │
│ │  postfix    │ │    │ └─────────────┘ │
│ │   rspamd    │ │    └─────────────────┘
│ └─────────────┘ │             │
└─────────────────┘             │
         │                      │
         └──────────┬───────────┘
                    │
            ┌─────────────┐
            │   MySQL     │
            │  Database   │
            │ (shared)    │
            └─────────────┘
```

## 🌐 **Service Endpoints**

- **Mailu Admin**: https://mail.yourdomain.com/admin/
- **Mailu Webmail**: https://mail.yourdomain.com/webmail/ 
- **Postal Interface**: https://postal.yourdomain.com/

## 📁 **Project Structure**

```
mail-server-integration/
├── README.md                                # This file
├── .gitignore                              # Git ignore rules
├── SETUP.md                                # Detailed setup guide
├── MIGRATION-SCRIPTS-GUIDE.md              # Database migration guide
├── migrate-mail-databases.sh               # Interactive migration script
├── rollback-mail-databases.sh              # Rollback/recovery script
├── mailu/                                  # Mailu mail server
│   ├── docker-compose.yml                  # Mailu services
│   ├── mailu.env.template                  # Environment template
│   └── postal.conf                         # Nginx proxy config
└── postal/                                 # Postal mail server
    ├── docker-compose.prod.yml.template    # Production template
    ├── postal.yml.template                 # Postal config template  
    ├── postal-setup-complete.sh            # Setup automation
    └── README.md                           # Postal-specific docs
```

## ⚙️ **Configuration**

### **Required Configuration Steps**

1. **Domain Setup**: Update `yourdomain.com` to your actual domain in all files
2. **SSL Certificates**: Ensure Let's Encrypt certificates are available
3. **Database Passwords**: Change all default passwords in templates  
4. **API Keys**: Generate secure random keys where marked
5. **DNS Records**: Configure MX, SPF, DKIM records as documented

### **Template Files**

All template files contain `<CHANGE_THIS>` placeholders that must be updated:

- `mailu/mailu.env.template` → `mailu/mailu.env`
- `postal/postal.yml.template` → `postal/postal.yml`
- `postal/docker-compose.prod.yml.template` → `postal/docker-compose.prod.yml`

## 🚀 **Deployment Guide**

### **Prerequisites**

- Docker & Docker Compose
- Domain with DNS control
- SSL certificates (Let's Encrypt recommended)
- Minimum 2GB RAM, 20GB storage

### **Production Deployment**

1. **Prepare Environment**:
   ```bash
   # Generate secure keys
   openssl rand -base64 16  # For SECRET_KEY
   openssl rand -base64 32  # For API_TOKEN  
   openssl rand -hex 32     # For postal secret_key
   ```

2. **Configure Services**:
   ```bash
   # Copy templates and update placeholders
   cp mailu/mailu.env.template mailu/mailu.env
   cp postal/postal.yml.template postal/postal.yml
   cp postal/docker-compose.prod.yml.template postal/docker-compose.prod.yml
   
   # Edit files to replace <CHANGE_THIS> values
   ```

3. **Start Services**:
   ```bash
   # Start Mailu first (creates shared network)
   cd mailu && docker compose up -d
   
   # Start Postal (connects to Mailu network)
   cd ../postal && docker compose -f docker-compose.prod.yml up -d
   ```

4. **Initial Setup**:
   ```bash
   # Run complete setup with your domain
   ./postal/postal-setup-complete.sh full yourdomain.com admin@yourdomain.com
   ```

## 🔧 **Management Tools**

### **Database Migration**
```bash
# Interactive migration to new database
./migrate-mail-databases.sh

# Rollback if needed
./rollback-mail-databases.sh
```

### **Postal Setup**
```bash  
# All setup options
./postal/postal-setup-complete.sh help

# Individual components
./postal/postal-setup-complete.sh init     # Server setup
./postal/postal-setup-complete.sh users    # Create users
./postal/postal-setup-complete.sh domain example.com test@email.com
```

### **Service Management**
```bash
# Mailu services
cd mailu && docker compose ps
cd mailu && docker compose logs front

# Postal services  
cd postal && docker compose -f docker-compose.prod.yml ps
cd postal && docker compose -f docker-compose.prod.yml logs web
```

## 🔒 **Security Considerations**

### **Required Security Updates**

1. **Change Default Passwords**: All template passwords must be updated
2. **Secure Database**: Use strong MySQL root and user passwords
3. **API Security**: Generate random API tokens and secret keys
4. **SSL/TLS**: Use valid certificates (Let's Encrypt recommended)
5. **Firewall**: Restrict access to management ports

### **Production Hardening**

- Remove `POSTAL_ALLOW_ANY_HOST=true` if not needed
- Set up proper DNS (SPF, DKIM, DMARC records)
- Configure rate limiting and anti-spam measures
- Regular security updates for Docker images
- Monitor logs for suspicious activity

## 📚 **Documentation**

- **[SETUP.md](./SETUP.md)**: Comprehensive setup guide
- **[MIGRATION-SCRIPTS-GUIDE.md](./MIGRATION-SCRIPTS-GUIDE.md)**: Database migration documentation
- **[postal/README.md](./postal/README.md)**: Postal-specific configuration
- **[README-POSTAL-NGINX-INTEGRATION.md](./README-POSTAL-NGINX-INTEGRATION.md)**: Technical integration details

## 🐛 **Troubleshooting**

### **Common Issues**

1. **Certificate Problems**: Check Let's Encrypt certificate paths
2. **Database Connection**: Verify MySQL credentials and network connectivity  
3. **CSRF Errors**: Ensure proper proxy headers in nginx configuration
4. **Port Conflicts**: Check that required ports (80, 443, 5000, 2525) are available

### **Health Checks**

```bash
# Check all services
docker compose ps
docker compose -f docker-compose.prod.yml ps

# Test connectivity
curl -I https://mail.yourdomain.com/
curl -I https://postal.yourdomain.com/

# Database connectivity
docker exec postal-db-1 mysql -u postal -p -e "SHOW DATABASES;"
```

## 📞 **Support**

- **Issues**: Create GitHub issues for bugs or questions
- **Documentation**: Check the docs/ folder for detailed guides
- **Logs**: Always include relevant log output when reporting issues

## 📄 **License**

[Add your license information here]

---

**Version**: 1.0  
**Last Updated**: September 2025  
**Status**: Production Ready ✅
