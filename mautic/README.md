# Mautic Marketing Automation

This directory contains the Mautic marketing automation platform configuration and setup.

## 🚀 Quick Setup

```bash
# 1. Copy and configure
cp ../docker-compose.mautic.yml docker-compose.yml
# Update all <CHANGE_THIS> placeholders in docker-compose.yml

# 2. Create required directories
mkdir -p config logs media

# 3. Start services
docker compose up -d

# 4. Access Mautic
# Local: http://localhost:8080
# With proxy: https://mautic.yourdomain.com
```

## 📁 Directory Structure

```
mautic/
├── README.md                 # This file
├── docker-compose.yml        # Mautic services (copy from docker-compose.mautic.yml)
├── config/                   # Mautic configuration files (auto-generated)
├── logs/                     # Application logs
├── media/                    # Uploaded media files
└── nginx-mautic.conf         # Nginx proxy configuration (optional)
```

## ⚙️ Configuration

### **Database Settings**
- **Host**: postal-db-1 (Shared with Postal)
- **Database**: mautic
- **User**: postal (Same as Postal)
- **Password**: Same as Postal database password

### **Email Integration**
Mautic is configured to use your existing Postal mail server:
- **SMTP Host**: postal-smtp-1:25 (via Docker network)
- **From Email**: noreply@yourdomain.com
- **Authentication**: None (internal network)

### **Web Access**
- **Local Development**: http://localhost:8080
- **Production**: Setup nginx proxy (see nginx-mautic.conf)

## 🔧 Initial Setup

### **1. First-time Setup Wizard**

After starting the containers, visit the web interface to complete setup:

1. **System Check**: Verify PHP requirements
2. **Database Setup**: Use the Docker database settings
3. **Admin User**: Create your admin account
4. **Email Configuration**: Configure SMTP settings

### **2. Email Configuration**

In Mautic admin panel → Configuration → Email Settings:

```
Transport: SMTP
SMTP Host: postal-smtp-1
SMTP Port: 25
SMTP Authentication: None
SMTP Encryption: None
From Email: noreply@yourdomain.com
From Name: Your Company
```

### **3. Cron Jobs**

Cron jobs are automatically handled by the `mautic_cron` container. These run every 5 minutes:

- Segment updates
- Campaign triggers
- Email queue processing
- Import processing
- Data cleanup

## 🌐 Nginx Proxy Setup

To access Mautic via https://mautic.yourdomain.com, add this to your Mailu nginx configuration:

```nginx
# Add to /home/ubuntu/ms/mailu/mautic.conf
server {
    listen 80;
    server_name mautic.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name mautic.yourdomain.com;
    
    # SSL configuration (use your existing certificates)
    ssl_certificate /certs/cert.pem;
    ssl_certificate_key /certs/key.pem;
    
    location / {
        proxy_pass http://mautic-web-1:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Increase timeout for large imports
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
```

Then mount it in your Mailu docker-compose.yml:
```yaml
volumes:
  - "./mautic.conf:/etc/nginx/conf.d/mautic.conf:ro"
```

## 📊 Features Included

### **Marketing Automation**
- Email campaigns and drip sequences
- Lead scoring and segmentation
- Landing page builder
- Form builder and tracking
- Social media monitoring

### **Integration Capabilities**
- **Email Sending**: Integrated with Postal SMTP
- **Database**: Shared MySQL 8.0 instance (postal-db-1) with persistent storage
- **Caching**: Redis for improved performance
- **Monitoring**: Health checks for all services
- **Unified Infrastructure**: Shares database and networking with Postal mail server

### **Performance Optimizations**
- Redis caching
- Automated cron jobs
- PHP memory and execution time tuning
- File upload size optimization

## 🔧 Management Commands

### **Service Management**
```bash
# Start services
docker compose up -d

# View logs
docker compose logs mautic
docker compose logs mautic_cron

# Access Mautic console
docker compose exec mautic bash
php bin/console mautic:segments:update

# Database backup
docker compose exec mautic_db mysqldump -u mautic -p mautic > mautic_backup.sql
```

### **Common Tasks**
```bash
# Clear cache
docker compose exec mautic php bin/console cache:clear

# Update segments
docker compose exec mautic php bin/console mautic:segments:update

# Process campaign triggers
docker compose exec mautic php bin/console mautic:campaigns:trigger

# Send queued emails
docker compose exec mautic php bin/console mautic:emails:send
```

## 🚨 Security Considerations

### **Required Updates**
1. Change all database passwords in docker-compose.yml
2. Generate secure MAUTIC_SECRET_KEY
3. Update MAUTIC_REQUEST_CONTEXT_HOST to your domain
4. Configure proper firewall rules

### **Production Hardening**
- Use HTTPS with valid SSL certificates
- Restrict database access
- Regular security updates
- Monitor logs for suspicious activity
- Set up proper backup procedures

## 📞 Troubleshooting

### **Common Issues**

1. **Database Connection**: Check MySQL credentials and network connectivity
2. **Email Sending**: Verify Postal SMTP configuration and network access
3. **Performance**: Monitor Redis cache usage and PHP memory limits
4. **Cron Jobs**: Check mautic_cron container logs for errors

### **Useful Commands**
```bash
# Check service status
docker compose ps

# View real-time logs
docker compose logs -f mautic

# Test email configuration
docker compose exec mautic php bin/console mautic:emails:send --test

# Check database connectivity
docker compose exec mautic_db mysql -u mautic -p -e "SHOW DATABASES;"
```

---

**Version**: 5.x  
**Integration**: Postal Mail Server  
**Status**: Production Ready ✅
