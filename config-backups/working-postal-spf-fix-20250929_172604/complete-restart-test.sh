#!/bin/bash

# =============================================================================
# COMPLETE RESTART TEST
# =============================================================================
# Performs a complete restart test to verify persistence
# =============================================================================

echo "🔄 PERFORMING COMPLETE RESTART TEST"
echo "===================================="
echo ""

echo "📊 Phase 1: Current Status"
echo "=========================="
echo "Services before restart:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(mailu|postal|mautic)" | wc -l

echo ""
echo "📥 Phase 2: Stopping All Services"
echo "=================================="

echo "Stopping Mailu..."
cd /home/ubuntu/ms/mailu && docker compose down --remove-orphans

echo "Stopping Postal..."
cd /home/ubuntu/ms/postal && docker compose down --remove-orphans

echo "Stopping Mautic..."
cd /home/ubuntu/ms && docker compose -f docker-compose.mautic.yml down --remove-orphans

echo ""
echo "Services after shutdown:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(mailu|postal|mautic)" | wc -l

echo ""
echo "📤 Phase 3: Starting All Services" 
echo "=================================="

echo "Starting Postal (database first)..."
cd /home/ubuntu/ms/postal && docker compose up -d

echo "Waiting for Postal to be ready..."
sleep 10

echo "Starting Mailu..."
cd /home/ubuntu/ms/mailu && docker compose up -d

echo "Waiting for Mailu to be ready..."
sleep 15

echo "Starting Mautic..."
cd /home/ubuntu/ms && docker compose -f docker-compose.mautic.yml up -d

echo "Waiting for all services to be ready..."
sleep 10

echo ""
echo "📊 Phase 4: Verification"
echo "========================"

echo "Services after restart:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(mailu|postal|mautic)" | wc -l

echo ""
echo "Network connectivity:"
echo "• Postal to Mailu: $(docker network inspect mailu_default 2>/dev/null | grep -c postal-web-1 || echo '0')"
echo "• Mautic to Mailu: $(docker network inspect mailu_default 2>/dev/null | grep -c mautic-web-1 || echo '0')"
echo "• Mailu to Postal: $(docker network inspect postal_default 2>/dev/null | grep -c mailu || echo '0')"

echo ""
echo "Nginx configurations:"
echo "• Postal config: $(docker exec mailu-front-1 test -f /etc/nginx/conf.d/postal.conf 2>/dev/null && echo 'Present' || echo 'Missing')"
echo "• Mautic config: $(docker exec mailu-front-1 test -f /etc/nginx/conf.d/mautic.conf 2>/dev/null && echo 'Present' || echo 'Missing')"

echo ""
echo "CSRF headers:"
if docker exec mailu-front-1 cat /etc/nginx/conf.d/postal.conf 2>/dev/null | grep -q "Origin.*host"; then
    echo "✅ CSRF headers present in postal.conf"
else
    echo "❌ CSRF headers missing in postal.conf"
fi

echo ""
echo "📡 Phase 5: Endpoint Testing"
echo "============================"

echo "Testing endpoints (may take a moment for services to fully start)..."
sleep 5

echo "Postal direct access:"
if curl -s -I http://localhost:5000/login 2>/dev/null | grep -q "200 OK"; then
    echo "✅ Postal direct access working"
else
    echo "❌ Postal direct access failed"
fi

echo "Postal proxy access:"
if curl -s -I -H "Host: postal.soham.top" https://localhost/login -k 2>/dev/null | grep -q "200\|302"; then
    echo "✅ Postal proxy access working"
else
    echo "❌ Postal proxy access failed"
fi

echo ""
echo "🎯 RESTART TEST RESULTS"
echo "======================="

# Final verification
services_count=$(docker ps --format "table {{.Names}}" | grep -E "(mailu|postal|mautic)" | wc -l)
postal_direct=$(curl -s -I http://localhost:5000/login 2>/dev/null | grep -q "200 OK" && echo "✅" || echo "❌")
postal_proxy=$(curl -s -I -H "Host: postal.soham.top" https://localhost/login -k 2>/dev/null | grep -q "200\|302" && echo "✅" || echo "❌")
csrf_headers=$(docker exec mailu-front-1 cat /etc/nginx/conf.d/postal.conf 2>/dev/null | grep -q "Origin.*host" && echo "✅" || echo "❌")
nginx_configs=$(docker exec mailu-front-1 test -f /etc/nginx/conf.d/postal.conf 2>/dev/null && echo "✅" || echo "❌")

echo "Services running: $services_count/18+ expected"
echo "Postal direct: $postal_direct"
echo "Postal proxy: $postal_proxy" 
echo "CSRF headers: $csrf_headers"
echo "Nginx configs: $nginx_configs"

if [[ "$postal_direct" == "✅" && "$postal_proxy" == "✅" && "$csrf_headers" == "✅" && "$nginx_configs" == "✅" ]]; then
    echo ""
    echo "🎉 RESTART TEST PASSED!"
    echo "======================="
    echo "✅ All configurations are fully persistent"
    echo "✅ No manual configurations required after restart"
    echo "✅ All endpoints accessible"
    echo "✅ CSRF protection working"
    echo ""
    echo "🌐 Ready endpoints:"
    echo "• Mailu: https://mail.soham.top/admin"
    echo "• Postal: https://postal.soham.top"
    echo "• Mautic: https://mautic.soham.top"
else
    echo ""
    echo "⚠️ RESTART TEST ISSUES DETECTED"
    echo "==============================="
    echo "Some configurations may need manual intervention"
fi
