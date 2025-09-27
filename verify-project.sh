#!/bin/bash
# =============================================================================
# Mail Server Integration - Project Verification Script
# =============================================================================
# This script verifies that the project is properly configured and ready to deploy
#
# Usage: ./verify-project.sh
# =============================================================================

set -e

echo "🔍 Mail Server Integration - Project Verification"
echo "================================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SUCCESS=0
WARNINGS=0
ERRORS=0

check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo -e "✅ ${GREEN}$description${NC}"
        return 0
    else
        echo -e "❌ ${RED}$description (missing: $file)${NC}"
        ((ERRORS++))
        return 1
    fi
}

check_template() {
    local template=$1
    local config=$2
    local description=$3
    
    if [ -f "$template" ]; then
        echo -e "✅ ${GREEN}$description template exists${NC}"
        
        if [ -f "$config" ]; then
            echo -e "⚠️  ${YELLOW}Warning: $config exists (remove before Git commit)${NC}"
            ((WARNINGS++))
        fi
        return 0
    else
        echo -e "❌ ${RED}$description template missing${NC}"
        ((ERRORS++))
        return 1
    fi
}

check_placeholders() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        local count=$(grep -c "<CHANGE_THIS" "$file" 2>/dev/null || echo "0")
        if [ "$count" -gt 0 ]; then
            echo -e "✅ ${GREEN}$description has $count placeholders${NC}"
            return 0
        else
            echo -e "⚠️  ${YELLOW}Warning: $description has no <CHANGE_THIS> placeholders${NC}"
            ((WARNINGS++))
            return 1
        fi
    else
        echo -e "❌ ${RED}$description not found${NC}"
        ((ERRORS++))
        return 1
    fi
}

echo -e "\n📁 Checking Project Structure..."
echo "================================"

# Core documentation
check_file "README.md" "Main README"
check_file "SETUP.md" "Setup guide"
check_file "LICENSE" "License file"
check_file ".gitignore" "Git ignore file"
check_file "CONTRIBUTING.md" "Contributing guide"

echo -e "\n📋 Checking Documentation..."
echo "============================="

check_file "MIGRATION-SCRIPTS-GUIDE.md" "Migration guide"
check_file "README-POSTAL-NGINX-INTEGRATION.md" "Technical integration guide"

echo -e "\n🔧 Checking Scripts..."
echo "====================="

check_file "migrate-mail-databases.sh" "Database migration script"
check_file "rollback-mail-databases.sh" "Rollback script"
check_file "postal/postal-setup-complete.sh" "Postal setup script"

# Check script permissions
if [ -f "migrate-mail-databases.sh" ]; then
    if [ -x "migrate-mail-databases.sh" ]; then
        echo -e "✅ ${GREEN}Migration script is executable${NC}"
    else
        echo -e "⚠️  ${YELLOW}Warning: Migration script not executable${NC}"
        ((WARNINGS++))
    fi
fi

echo -e "\n📮 Checking Mailu Configuration..."
echo "================================="

check_file "mailu/docker-compose.yml" "Mailu Docker Compose"
check_file "mailu/postal.conf" "Nginx proxy configuration"
check_template "mailu/mailu.env.template" "mailu/mailu.env" "Mailu environment"
check_placeholders "mailu/mailu.env.template" "Mailu environment template"

echo -e "\n📬 Checking Postal Configuration..."
echo "=================================="

check_file "postal/README.md" "Postal documentation"
check_file "postal/docker-compose.yml" "Postal Docker Compose (dev)"
check_template "postal/docker-compose.prod.yml.template" "postal/docker-compose.prod.yml" "Postal production compose"
check_template "postal/postal.yml.template" "postal/postal.yml" "Postal configuration"
check_placeholders "postal/docker-compose.prod.yml.template" "Postal production compose template"
check_placeholders "postal/postal.yml.template" "Postal configuration template"

echo -e "\n🔒 Checking Security..."
echo "======================"

# Check for sensitive information in templates
echo "🔍 Scanning for potential sensitive data in templates..."

SENSITIVE_PATTERNS=("password.*=.*[^<]" "secret.*=.*[^<]" "token.*=.*[^<]" "key.*=.*[^<]")
TEMPLATE_FILES=("mailu/mailu.env.template" "postal/postal.yml.template" "postal/docker-compose.prod.yml.template")

for file in "${TEMPLATE_FILES[@]}"; do
    if [ -f "$file" ]; then
        for pattern in "${SENSITIVE_PATTERNS[@]}"; do
            if grep -q -E "$pattern" "$file" 2>/dev/null; then
                echo -e "⚠️  ${YELLOW}Warning: Potential sensitive data in $file${NC}"
                ((WARNINGS++))
                break
            fi
        done
    fi
done

# Check for actual sensitive files
if [ -f "mailu/mailu.env" ] || [ -f "postal/postal.yml" ] || [ -f "postal/docker-compose.prod.yml" ]; then
    echo -e "⚠️  ${YELLOW}Warning: Actual config files present (should be .gitignored)${NC}"
    ((WARNINGS++))
else
    echo -e "✅ ${GREEN}No sensitive config files present${NC}"
fi

echo -e "\n📊 Verification Summary"
echo "======================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "🎉 ${GREEN}Perfect! Project is ready for GitHub.${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "✅ ${GREEN}Good! Project is ready with $WARNINGS warnings.${NC}"
    echo -e "   ${YELLOW}Address warnings before production deployment.${NC}"
else
    echo -e "❌ ${RED}Issues found: $ERRORS errors, $WARNINGS warnings.${NC}"
    echo -e "   ${RED}Fix errors before proceeding.${NC}"
fi

echo -e "\n🚀 Next Steps:"
echo "============="
echo "1. Review any warnings above"
echo "2. git add . && git commit -m 'Initial mail server integration'"  
echo "3. git push origin main"
echo "4. Create deployment by copying templates to actual config files"
echo "5. Update all <CHANGE_THIS> placeholders in config files"
echo "6. Deploy: cd mailu && docker compose up -d"
echo "7. Deploy: cd postal && docker compose -f docker-compose.prod.yml up -d"

exit $ERRORS
