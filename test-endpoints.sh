#!/bin/bash

echo "=== Testing User Registration ==="
RESPONSE=$(curl -s -X POST http://localhost:8080/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@example.com","password":"password123","firstName":"Test","lastName":"User"}')

echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"

echo ""
echo "=== Testing Admin Login ==="
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@eventplatform.com","password":"admin123"}')

echo "$LOGIN_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$LOGIN_RESPONSE"

# Extract token if login successful
TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

if [ ! -z "$TOKEN" ]; then
  echo ""
  echo "=== Testing Protected Endpoint ==="
  curl -s -X GET http://localhost:8080/v1/users/me \
    -H "Authorization: Bearer $TOKEN" | python3 -m json.tool 2>/dev/null || echo "Failed to get user"
fi

