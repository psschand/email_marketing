# Environment Variables Reference

## Mailu Configuration (mailu.env)

```bash
# Domain Settings
DOMAIN=soham.top
HOSTNAMES=mail.soham.top
POSTMASTER=admin

# Security
SECRET_KEY=MailuSecureKey123
INITIAL_ADMIN_ACCOUNT=admin
INITIAL_ADMIN_DOMAIN=soham.top
INITIAL_ADMIN_PW=admin123456
API_TOKEN=MailuApiToken123456789012345678901

# Database
DB_FLAVOR=mysql
DB_HOST=postal-db-1
DB_PORT=3306
DB_NAME=mailu
DB_USER=mailu
DB_PW=mailu_secure_password_123

# SSL/TLS
TLS_FLAVOR=letsencrypt

# Features
ADMIN=true
WEBMAIL=webmail
ANTISPAM=rspamd
ANTIVIRUS=none
WEBDAV=webdav
```

## Postal Configuration (postal.yml)

```yaml
web_server:
  host: 0.0.0.0
  port: 5000

mysql:
  host: postal-db-1
  port: 3306
  username: postal  
  password: postal_password
  database: postal

smtp_server:
  port: 25
  tls_enabled: true

main_db:
  host: postal-db-1
  port: 3306
  username: postal
  password: postal_password
```

## Mautic Configuration (docker-compose.mautic.yml)

```yaml
environment:
  MAUTIC_DB_HOST: postal-db-1
  MAUTIC_DB_USER: mautic
  MAUTIC_DB_PASSWORD: mautic_secure_password_123
  MAUTIC_DB_NAME: mautic
  MAUTIC_DB_PORT: 3306
  
  MAUTIC_TRUSTED_PROXIES: '["0.0.0.0/0"]'
  MAUTIC_TRUSTED_HOSTS: '["mautic.soham.top"]'
```

## MySQL Database Users

```sql
-- Root user
CREATE USER 'root'@'%' IDENTIFIED BY 'postal_root_password';

-- Mailu user  
CREATE USER 'mailu'@'%' IDENTIFIED BY 'mailu_secure_password_123';
GRANT ALL PRIVILEGES ON mailu.* TO 'mailu'@'%';

-- Postal user
CREATE USER 'postal'@'%' IDENTIFIED BY 'postal_password';  
GRANT ALL PRIVILEGES ON postal.* TO 'postal'@'%';

-- Mautic user
CREATE USER 'mautic'@'%' IDENTIFIED BY 'mautic_secure_password_123';
GRANT ALL PRIVILEGES ON mautic.* TO 'mautic'@'%';
```

## CloudFlare Certificate Configuration

```ini
# /etc/letsencrypt/cloudflare.ini
dns_cloudflare_api_token = pon7wP7lplxzmbLCTtdjdM1zxWktDlPvssxLSj-n
```

## Docker Network Configuration

```yaml
networks:
  mailu_default:
    external: true
  postal_default:  
    external: true
```

---

**⚠️ Security Note**: All passwords and API tokens shown here are the actual production values. Store this file securely and restrict access.
