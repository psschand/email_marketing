# Contributing to Mail Server Integration

Thank you for your interest in contributing to this project! This guide will help you get started.

## 🤝 **How to Contribute**

### **Reporting Issues**

1. **Search existing issues** to avoid duplicates
2. **Use the issue template** (if available)
3. **Include relevant information**:
   - Operating system and version
   - Docker version and Docker Compose version
   - Steps to reproduce the issue
   - Expected vs actual behavior
   - Relevant log output (sanitize sensitive information)

### **Suggesting Features**

1. **Open a feature request** with detailed description
2. **Explain the use case** and benefits
3. **Consider backwards compatibility**
4. **Be willing to help implement** if possible

### **Submitting Changes**

1. **Fork the repository** and create a feature branch
2. **Follow the coding standards** outlined below
3. **Test your changes** thoroughly
4. **Update documentation** as needed
5. **Submit a pull request** with clear description

## 🏗️ **Development Setup**

### **Prerequisites**

- Docker & Docker Compose
- Git
- Text editor or IDE
- Basic understanding of:
  - Docker containerization
  - Nginx configuration
  - MySQL databases
  - Email server concepts

### **Local Development**

```bash
# 1. Fork and clone
git clone https://github.com/yourusername/mail-server-integration.git
cd mail-server-integration

# 2. Create development environment
cp mailu/mailu.env.template mailu/mailu.env.dev
cp postal/postal.yml.template postal/postal.yml.dev
cp postal/docker-compose.prod.yml.template postal/docker-compose.dev.yml

# 3. Update configs for development
# Use development-safe values, different ports, etc.

# 4. Test changes
docker compose -f mailu/docker-compose.yml up -d
docker compose -f postal/docker-compose.dev.yml up -d
```

## 📝 **Coding Standards**

### **Shell Scripts**

- Use `#!/bin/bash` shebang
- Enable strict mode: `set -e`
- Use meaningful variable names
- Add comments for complex logic
- Include usage examples in script headers
- Use `echo` for user feedback

### **Docker Compose**

- Use version 3.8+ format
- Include meaningful service names
- Use environment variables for configuration
- Include health checks where appropriate
- Document port mappings and volumes

### **Documentation**

- Use clear, concise language
- Include examples and code snippets
- Update relevant README files
- Follow Markdown best practices
- Use emojis consistently for visual clarity

### **Configuration Files**

- Use meaningful comments
- Group related settings
- Include security warnings for sensitive values
- Provide example values where helpful
- Use consistent naming conventions

## 🧪 **Testing**

### **Before Submitting**

1. **Test basic functionality**:
   ```bash
   # Verify services start correctly
   docker compose ps
   
   # Check service health
   curl -I http://localhost/
   
   # Verify logs are clean
   docker compose logs
   ```

2. **Test migration scripts**:
   ```bash
   # Test with dry-run or development data
   ./migrate-mail-databases.sh
   ```

3. **Validate configurations**:
   ```bash
   # Check docker-compose syntax
   docker compose config
   
   # Verify nginx config
   docker compose exec front nginx -t
   ```

### **Test Cases to Consider**

- Fresh installation
- Upgrade scenarios
- Migration between databases
- SSL certificate changes
- Network connectivity issues
- Service restart behavior

## 🔒 **Security Guidelines**

### **Sensitive Information**

- **Never commit** actual passwords, API keys, or certificates
- **Use templates** with `<CHANGE_THIS>` placeholders
- **Sanitize logs** before sharing in issues
- **Review diffs** before committing

### **Best Practices**

- Generate strong random passwords
- Use environment variables for secrets
- Validate user input in scripts
- Include security warnings in documentation
- Follow least privilege principle

## 📋 **Pull Request Process**

### **Before Creating PR**

1. **Update your fork** with latest changes
2. **Create feature branch** from main
3. **Make focused commits** with clear messages
4. **Test thoroughly** in development environment
5. **Update documentation** if needed

### **PR Guidelines**

- **Clear title** describing the change
- **Detailed description** explaining the purpose
- **Link related issues** if applicable
- **Include testing notes** for reviewers
- **Mark breaking changes** clearly

### **Review Process**

1. **Automated checks** must pass
2. **Code review** by maintainers
3. **Testing** in clean environment
4. **Documentation review** if applicable
5. **Merge** when approved

## 🏷️ **Commit Message Format**

Use conventional commits format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(postal): add automated domain setup
fix(mailu): resolve SSL certificate loading issue
docs(migration): update database migration guide
```

## 🆘 **Getting Help**

- **Documentation**: Check SETUP.md and other guides
- **Issues**: Search existing issues for solutions
- **Discussions**: Use GitHub Discussions for questions
- **Community**: Be respectful and constructive

## 📄 **License**

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to make this project better! 🎉
