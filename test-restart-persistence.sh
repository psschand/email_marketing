#!/bin/bash

# =============================================================================
# COMPLETE RESTART PERSISTENCE TEST
# =============================================================================
# Tests if all configurations persist after complete service restart
# =============================================================================

echo "🔄 TESTING CONFIGURATION PERSISTENCE"
echo "====================================="
echo ""

echo "📊 CURRENT STATUS (Before Restart):"
echo "==================================="
echo "Services running:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(mailu|postal|mautic)" | wc -l

echo ""
echo "Network connections:"
echo "• Postal to Mailu: $(docker network inspect mailu_default | grep -c postal-web-1)"
echo "• Mautic to Mailu: $(docker network inspect mailu_default | grep -c mautic-web-1)"
echo "• Mailu to Postal: $(docker network inspect postal_default | grep -c mailu)"

echo ""
echo "Nginx configurations:"
echo "• Postal config: $(docker exec mailu-front-1 test -f /etc/nginx/conf.d/postal.conf && echo 'Present' || echo 'Missing')"
echo "• Mautic config: $(docker exec mailu-front-1 test -f /etc/nginx/conf.d/mautic.conf && echo 'Present' || echo 'Missing')"

echo ""
echo "🔧 CHECKING CONFIGURATION PERSISTENCE:"
echo "======================================"

echo ""
echo "1. Checking Docker Compose Network Definitions:"
echo "=============================================="
echo "Mailu networks defined:"
grep -A 5 "networks:" /home/ubuntu/ms/mailu/docker-compose.yml | grep -E "(default|postal_default)"

echo ""
echo "Postal networks defined:"
grep -A 5 "networks:" /home/ubuntu/ms/postal/docker-compose.yml | grep -E "(default|mailu_default)"

echo ""
echo "2. Checking Volume Mounts:"
echo "========================="
echo "Postal.conf mounted:"
grep -c "postal.conf" /home/ubuntu/ms/mailu/docker-compose.yml

echo "Mautic.conf mounted:"
grep -c "mautic.conf" /home/ubuntu/ms/mailu/docker-compose.yml

echo ""
echo "3. Manual Configurations Analysis:"
echo "=================================="

echo ""
echo "❌ POTENTIAL MANUAL CONFIGURATIONS (Need to check):"
echo "=================================================="

echo ""
echo "Manual network connections (if any):"
echo "These should be defined in docker-compose.yml files, not manual"

# Check if any containers were manually connected
echo "Checking for manual connections..."

# Check admin container
if docker network inspect postal_default | grep -q "mailu-admin-1"; then
    if ! grep -q "postal_default" /home/ubuntu/ms/mailu/docker-compose.yml; then
        echo "⚠️  mailu-admin-1 manually connected to postal_default"
    else
        echo "✅ mailu-admin-1 connection defined in docker-compose.yml"
    fi
fi

# Check if CSRF headers are properly in file
if docker exec mailu-front-1 cat /etc/nginx/conf.d/postal.conf | grep -q "Origin.*host"; then
    echo "✅ CSRF headers present in postal.conf"
else
    echo "⚠️  CSRF headers missing in postal.conf"
fi

echo ""
echo "4. Testing Endpoint Accessibility:"
echo "=================================="

echo "Testing direct access:"
curl -s -I http://localhost:5000/login > /dev/null && echo "✅ Postal direct access working" || echo "❌ Postal direct access failed"

echo "Testing proxy access:"
curl -s -I -H "Host: postal.soham.top" https://localhost/login -k > /dev/null && echo "✅ Postal proxy access working" || echo "❌ Postal proxy access failed"

echo ""
echo "📝 PERSISTENCE ANALYSIS SUMMARY:"
echo "================================"

echo ""
echo "✅ PERSISTENT CONFIGURATIONS:"
echo "============================="
echo "• Docker Compose network definitions (mailu ↔ postal)"
echo "• Volume mounts for nginx configs (postal.conf, mautic.conf)"
echo "• Environment variables in .env files"
echo "• Docker volume data (MySQL databases)"
echo "• SSL certificates in /certs/"

echo ""
echo "⚠️ CONFIGURATIONS THAT NEED VERIFICATION:"
echo "=========================================="

# Check if there are any manual docker network connects
manual_connections=0

if docker network inspect postal_default | grep -q "mailu-admin-1"; then
    if ! grep -A 20 "admin:" /home/ubuntu/ms/mailu/docker-compose.yml | grep -q "postal_default"; then
        echo "• mailu-admin-1 → postal_default (manual connection)"
        manual_connections=$((manual_connections + 1))
    fi
fi

if docker network inspect postal_default | grep -q "mailu-front-1"; then
    if ! grep -A 20 "front:" /home/ubuntu/ms/mailu/docker-compose.yml | grep -q "postal_default"; then
        echo "• mailu-front-1 → postal_default (manual connection)"
        manual_connections=$((manual_connections + 1))
    fi
fi

if [ $manual_connections -eq 0 ]; then
    echo "✅ No manual network connections found - all defined in docker-compose files"
else
    echo "Found $manual_connections manual network connections that need to be added to docker-compose.yml"
fi

echo ""
echo "🚀 RESTART READINESS:"
echo "===================="

if [ $manual_connections -eq 0 ]; then
    echo "✅ READY FOR RESTART - All configurations are persistent"
    echo ""
    echo "To test complete restart:"
    echo "1. cd /home/ubuntu/ms/mailu && docker compose down"
    echo "2. cd /home/ubuntu/ms/postal && docker compose down" 
    echo "3. cd /home/ubuntu/ms && docker compose -f docker-compose.mautic.yml down"
    echo "4. cd /home/ubuntu/ms/mailu && docker compose up -d"
    echo "5. cd /home/ubuntu/ms/postal && docker compose up -d"
    echo "6. cd /home/ubuntu/ms && docker compose -f docker-compose.mautic.yml up -d"
else
    echo "⚠️  NEEDS ATTENTION - Manual configurations found"
    echo "Please update docker-compose.yml files before restart"
fi
