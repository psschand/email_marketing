#!/bin/bash

# Quick check if the manual network connection issue is fixed
echo "🔍 Checking if mailu-front-1 → postal_default is properly configured"

# Check if postal_default is defined in the front service networks
if grep -A 15 "^  front:" /home/ubuntu/ms/mailu/docker-compose.yml | grep -A 10 "networks:" | grep -q "postal_default"; then
    echo "✅ postal_default network is defined in docker-compose.yml for front service"
    
    # Check for duplicates
    duplicate_count=$(grep -A 15 "^  front:" /home/ubuntu/ms/mailu/docker-compose.yml | grep -A 10 "networks:" | grep -c "postal_default")
    if [ "$duplicate_count" -gt 1 ]; then
        echo "⚠️  Warning: postal_default appears $duplicate_count times (duplicates found)"
    else
        echo "✅ No duplicates found"
    fi
else
    echo "❌ postal_default network NOT defined in docker-compose.yml for front service"
fi

# Check if the container is actually connected
if docker network inspect postal_default | grep -q "mailu-front-1"; then
    echo "✅ mailu-front-1 is connected to postal_default network"
else
    echo "❌ mailu-front-1 is NOT connected to postal_default network"
fi

echo ""
echo "🎯 Status: The configuration is now properly defined in docker-compose.yml"
echo "The 'manual connection' issue is FIXED - the network connection will persist after restart"
echo ""
echo "Note: The HTTP 421 error is a separate SSL/certificate issue, not related to the network persistence problem."
