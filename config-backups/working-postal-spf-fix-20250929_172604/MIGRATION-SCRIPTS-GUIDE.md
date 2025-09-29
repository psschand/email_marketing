# 📧 Mail Server Database Migration Scripts

## Overview
Two interactive scripts to automate MySQL database migration for Mailu and Postal mail servers:

- **`migrate-mail-databases.sh`** - Main migration script
- **`rollback-mail-databases.sh`** - Rollback/recovery script

## 🚀 Quick Start

### Prerequisites
```bash
# Install MySQL client
sudo apt update && sudo apt install mysql-client -y

# Ensure scripts are executable
chmod +x migrate-mail-databases.sh rollback-mail-databases.sh
```

### Run Migration
```bash
./migrate-mail-databases.sh
```

### Run Rollback (if needed)
```bash
./rollback-mail-databases.sh
```

## 📋 Migration Script Features

### 🔧 **Interactive Configuration**
- Guided prompts for new database settings
- Connection validation before migration
- Multiple migration types supported

### 🛡️ **Safety Features**
- Automatic backup creation with timestamps
- Configuration file backups
- Connection testing before proceeding
- Rollback capability

### 🔄 **Migration Types**
1. **External MySQL Server** - Migrate to remote MySQL
2. **New Local Container** - Set up fresh local MySQL
3. **Update Credentials** - Change existing database credentials

### ⚙️ **Automated Tasks**
- Database creation and permission setup
- Configuration file updates (`mailu.env`, `postal.yml`)
- Docker Compose network connectivity
- Service restart and health verification
- Data migration with SQL backups

## 📖 Usage Examples

### Example 1: Migrate to External MySQL Server
```bash
./migrate-mail-databases.sh

# Interactive prompts:
Select migration type: 1
MySQL Host: mysql.example.com
MySQL Port: 3306
MySQL Username: mailuser
MySQL Password: ********
Mailu Database Name: mailu_prod
Postal Database Name: postal_prod
```

### Example 2: Update Database Credentials
```bash
./migrate-mail-databases.sh

# Interactive prompts:
Select migration type: 3
MySQL Host: localhost
MySQL Port: 3306
MySQL Username: new_user
MySQL Password: ********
Mailu Database Name: mailu
Postal Database Name: postal
```

## 🗂️ Files Created During Migration

### Backup Files
```
mailu.env.backup.YYYYMMDD_HHMMSS     # Mailu configuration backup
postal.yml.backup.YYYYMMDD_HHMMSS    # Postal configuration backup
mailu_backup_YYYYMMDD_HHMMSS.sql     # Mailu database backup
postal_backup_YYYYMMDD_HHMMSS.sql    # Postal database backup
```

### Updated Configuration Files
```
/home/ubuntu/ms/mailu/mailu.env      # Updated with new DB settings
/home/ubuntu/ms/postal/postal.yml    # Updated with new DB settings
```

## 🔧 Migration Process Details

### Phase 1: Prerequisites Check
- Validates MySQL client installation
- Checks Docker availability
- Verifies directory structure
- Tests file permissions

### Phase 2: Database Configuration
- Interactive collection of new database details
- Connection validation to target MySQL server
- Database and user creation with proper permissions

### Phase 3: Backup Phase
- Automatic backup of existing databases
- Configuration file backups with timestamps
- Safe rollback preparation

### Phase 4: Configuration Update
- Updates `mailu.env` with new database settings:
  ```env
  DB_FLAVOR=mysql
  DB_HOST=your_host
  DB_PORT=3306
  DB_USER=your_user
  DB_PW=your_password
  DB_NAME=mailu
  ```
- Updates `postal.yml` with new database settings:
  ```yaml
  main_db:
    host: your_host
    port: 3306
    username: your_user
    password: your_password
    database: postal
  ```

### Phase 5: Data Migration
- Imports existing data from backup files
- Handles schema migration automatically
- Verifies data integrity

### Phase 6: Service Restart
- Graceful service shutdown
- Configuration reload
- Network connectivity setup
- Health verification

## 🚨 Rollback Procedure

If migration fails or issues occur:

```bash
./rollback-mail-databases.sh
```

The rollback script will:
1. List available backup files
2. Allow selection of configurations to restore
3. Restore previous configurations
4. Restart services with original settings

## 🔍 Verification Commands

After migration, verify with these commands:

```bash
# Check database connectivity
docker exec mailu-admin-1 env | grep DB_
docker exec mailu-admin-1 nc -zv NEW_HOST 3306

# Check service health
docker ps --filter name=mailu --filter name=postal

# Check database content
mysql -h NEW_HOST -u NEW_USER -p -e "SHOW DATABASES;"
mysql -h NEW_HOST -u NEW_USER -p -e "USE mailu; SHOW TABLES;"

# Test web interfaces
curl -I http://localhost/admin/
curl -I http://localhost:5001/
```

## 🛠️ Troubleshooting

### Common Issues

**Connection Refused:**
```bash
# Check if MySQL server is running
telnet NEW_HOST 3306

# Verify credentials
mysql -h NEW_HOST -u NEW_USER -p
```

**Permission Denied:**
```bash
# Grant proper permissions
mysql -h NEW_HOST -u root -p -e "GRANT ALL ON *.* TO 'NEW_USER'@'%';"
```

**Service Won't Start:**
```bash
# Check logs
docker logs mailu-admin-1
docker logs postal-web-1

# Verify configuration
docker exec mailu-admin-1 env | grep DB_
```

## 📊 Migration Scenarios

### Scenario 1: Local to Cloud Database
- **Use Case**: Moving from local MySQL to AWS RDS, Google Cloud SQL, etc.
- **Benefits**: Better availability, managed backups, scaling
- **Considerations**: Network latency, connection limits

### Scenario 2: Container to Dedicated Server  
- **Use Case**: Moving from Docker MySQL to dedicated MySQL server
- **Benefits**: Better performance, dedicated resources
- **Considerations**: Network configuration, firewall rules

### Scenario 3: Credential Rotation
- **Use Case**: Regular security maintenance
- **Benefits**: Enhanced security posture
- **Considerations**: Service downtime, coordination

## 🔐 Security Best Practices

1. **Use Strong Passwords**: Generate complex database passwords
2. **Network Security**: Use SSL/TLS for database connections
3. **Access Control**: Limit database user permissions
4. **Backup Security**: Encrypt and secure backup files
5. **Regular Rotation**: Schedule periodic credential updates

## 📈 Performance Considerations

### Database Sizing
- **Mailu Database**: ~10-50MB for typical installations
- **Postal Database**: Varies based on mail volume
- **Message Databases**: Can grow significantly with usage

### Network Optimization
- **Local Network**: <1ms latency preferred
- **Remote Database**: <10ms latency recommended
- **Connection Pooling**: Consider for high-volume setups

## 🎯 Advanced Usage

### Custom Migration Paths
Edit the script variables for non-standard installations:
```bash
MAILU_PATH="/custom/path/to/mailu"
POSTAL_PATH="/custom/path/to/postal"
```

### Automated Execution
For scripted deployments, prepare answers in advance:
```bash
# Create answer file
echo -e "1\nmysql.example.com\n3306\nmailuser\npassword123\nmailu\npostal" > migration.answers

# Run with input redirection
./migrate-mail-databases.sh < migration.answers
```

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review log files in `/var/log/`
3. Verify network connectivity and permissions
4. Use the rollback script if needed
5. Consult the main documentation: `README-POSTAL-NGINX-INTEGRATION.md`

---

**Version**: 1.0  
**Compatibility**: Ubuntu 20.04+, Docker 20.10+, MySQL 8.0+  
**Last Updated**: September 2025
