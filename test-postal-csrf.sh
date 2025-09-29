#!/bin/bash

echo "🔍 TESTING POSTAL CSRF HEADERS"
echo "==============================="

echo ""
echo "1. Testing direct Postal access (should work):"
curl -s -I http://localhost:5000/login | head -3

echo ""
echo "2. Testing nginx proxy access:"
curl -s -I -H "Host: postal.soham.top" https://localhost/login -k | head -3

echo ""
echo "3. Checking nginx CSRF headers configuration:"
docker exec mailu-front-1 cat /etc/nginx/conf.d/postal.conf | grep -A 2 -B 1 "Origin\|Referer"

echo ""
echo "4. Testing with full headers (simulating browser request):"
curl -s -I -H "Host: postal.soham.top" \
     -H "Origin: https://postal.soham.top" \
     -H "Referer: https://postal.soham.top/" \
     -H "User-Agent: Mozilla/5.0" \
     https://localhost/login -k | head -3

echo ""
echo "✨ POSTAL LOGIN TEST COMPLETE"
echo ""
echo "📝 Next Steps:"
echo "1. Clear browser cache/cookies for postal.soham.top"
echo "2. Try logging in with: admin@localhost / password"
echo "3. Or try: admin@soham.top / password"
echo "4. URL: https://postal.soham.top"
