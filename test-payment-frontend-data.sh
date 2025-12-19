#!/bin/bash

echo "🔍 Testing Payment Data for Frontend"
echo "===================================="
echo ""

API_BASE="http://localhost:8080"

# Test with a known user that has payments
echo "Testing with user ID 2 (known to have payment data)..."
echo ""

echo "1. Payment Intents for user 2:"
curl -s "$API_BASE/v1/payments/intents/user/2" | jq '.[] | {intentId, status, amount}' 2>/dev/null || echo "No intents found"
echo ""

echo "2. Payments for user 2:"
curl -s "$API_BASE/v1/payments/user/2" | jq '.[] | {paymentId, status, amount}' 2>/dev/null || echo "No payments found"
echo ""

echo "3. Summary calculation:"
INTENTS=$(curl -s "$API_BASE/v1/payments/intents/user/2" | jq 'length' 2>/dev/null || echo "0")
PAYMENTS=$(curl -s "$API_BASE/v1/payments/user/2" | jq 'length' 2>/dev/null || echo "0")

echo "  - Payment Intents: $INTENTS"
echo "  - Payments: $PAYMENTS"
echo "  - Total: $((INTENTS + PAYMENTS))"
echo ""

echo "4. Status breakdown:"
echo "  Completed (SUCCEEDED):"
curl -s "$API_BASE/v1/payments/user/2" | jq '[.[] | select(.status == "SUCCEEDED")] | length' 2>/dev/null || echo "0"
echo "  Pending (REQUIRES_PAYMENT_METHOD):"
curl -s "$API_BASE/v1/payments/intents/user/2" | jq '[.[] | select(.status == "REQUIRES_PAYMENT_METHOD")] | length' 2>/dev/null || echo "0"
echo ""

echo "5. Total paid amount:"
curl -s "$API_BASE/v1/payments/user/2" | jq '[.[] | select(.status == "SUCCEEDED") | .amount] | add' 2>/dev/null || echo "0"
echo ""

echo "✅ Test complete!"
echo ""
echo "To test in frontend:"
echo "1. Login with user ID 2 (or user that has payments)"
echo "2. Go to My Payments page"
echo "3. Check browser console (F12) for debug logs"
echo "4. Verify summary shows correct data"

