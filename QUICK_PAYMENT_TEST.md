# 💳 Quick Payment Test

## Fastest Way to Test Payment

### Option 1: Automated Script
```bash
./test-payment.sh
```

### Option 2: Quick Manual Test

```bash
# 1. Login and get token
TOKEN=$(curl -s -X POST "http://localhost:8080/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@example.com","password":"password123"}' \
  | jq -r '.token')

# 2. Create reservation (use existing event ID, e.g., 1)
RESERVATION=$(curl -s -X POST "http://localhost:8080/v1/reservations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"userId":2,"eventId":1,"quantity":1,"idempotencyKey":"quick-test-123"}')

RESERVATION_ID=$(echo $RESERVATION | jq -r '.reservationId')
TOTAL=$(echo $RESERVATION | jq -r '.totalPrice')

# 3. Create payment intent
INTENT=$(curl -s -X POST "http://localhost:8080/v1/payments/intents" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"reservationId\":\"$RESERVATION_ID\",\"userId\":2,\"amount\":$TOTAL,\"currency\":\"USD\",\"paymentMethod\":\"CARD\",\"description\":\"Test\",\"idempotencyKey\":\"quick-pay-123\"}")

INTENT_ID=$(echo $INTENT | jq -r '.intentId')
echo "Payment Intent: $INTENT_ID"

# 4. Capture payment
curl -X POST "http://localhost:8080/v1/payments/intents/$INTENT_ID/capture" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

## Common Issues

**Amount mismatch?** Get exact total:
```bash
TOTAL=$(curl -s "http://localhost:8080/v1/reservations/$RESERVATION_ID" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.totalPrice')
```

**Reservation already confirmed?** Create new one:
```bash
# Don't confirm it - go straight to payment
```

See `PAYMENT_TESTING_GUIDE.md` for full details.
