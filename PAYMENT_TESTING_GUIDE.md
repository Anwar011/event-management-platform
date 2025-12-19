# 💳 Payment Service Testing Guide

This guide explains how to test the payment functionality in the Event Management Platform.

## 📋 Payment Flow Overview

The payment system supports two flows:

### 1. **Modern Payment Intent Flow** (Recommended)
```
1. Create Reservation (PENDING state)
2. Create Payment Intent
3. Capture Payment Intent (processes payment & confirms reservation)
```

### 2. **Legacy Payment Flow**
```
1. Create Reservation (PENDING state)
2. Create Payment directly (processes payment & confirms reservation)
```

## 🚀 Quick Start - Automated Testing

Run the automated test script:

```bash
./test-payment.sh
```

This script will:
- Create a test user
- Create an event
- Create a reservation
- Test both payment flows
- Show detailed responses

## 📝 Manual Testing Steps

### Prerequisites

1. **Get Authentication Token**
```bash
# Register a user
curl -X POST "http://localhost:8080/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Password123",
    "firstName": "Test",
    "lastName": "User"
  }'

# Login to get token
TOKEN=$(curl -s -X POST "http://localhost:8080/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Password123"}' \
  | jq -r '.token')

echo "Token: $TOKEN"
```

2. **Create an Event**
```bash
EVENT_ID=$(curl -s -X POST "http://localhost:8080/v1/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Event",
    "description": "Test",
    "eventType": "CONFERENCE",
    "venue": "Test Venue",
    "address": "123 Test St",
    "city": "Test City",
    "state": "TS",
    "country": "US",
    "postalCode": "12345",
    "startDate": "2030-07-01T10:00:00",
    "endDate": "2030-07-01T18:00:00",
    "capacity": 100,
    "price": 99.99,
    "organizerId": 1
  }' | jq -r '.id')

echo "Event ID: $EVENT_ID"

# Publish the event
curl -X POST "http://localhost:8080/v1/events/$EVENT_ID/publish"
```

3. **Create a Reservation**
```bash
RESERVATION=$(curl -s -X POST "http://localhost:8080/v1/reservations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "userId": 1,
    "eventId": '$EVENT_ID',
    "quantity": 2,
    "idempotencyKey": "test-resv-123"
  }')

RESERVATION_ID=$(echo $RESERVATION | jq -r '.reservationId')
RESERVATION_TOTAL=$(echo $RESERVATION | jq -r '.totalPrice')

echo "Reservation ID: $RESERVATION_ID"
echo "Total: $RESERVATION_TOTAL"
```

### Testing Payment Intent Flow (Modern API)

#### Step 1: Create Payment Intent
```bash
INTENT=$(curl -s -X POST "http://localhost:8080/v1/payments/intents" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "reservationId": "'$RESERVATION_ID'",
    "userId": 1,
    "amount": '$RESERVATION_TOTAL',
    "currency": "USD",
    "paymentMethod": "CARD",
    "description": "Ticket purchase",
    "idempotencyKey": "pay-intent-123"
  }')

INTENT_ID=$(echo $INTENT | jq -r '.intentId')
echo "Payment Intent ID: $INTENT_ID"
echo $INTENT | jq '.'
```

**Expected Response:**
```json
{
  "id": 1,
  "intentId": "PI-XXXXXXXX",
  "reservationId": "RES-XXXXXXXX",
  "userId": 1,
  "amount": 199.98,
  "currency": "USD",
  "status": "REQUIRES_PAYMENT_METHOD",
  "paymentMethod": "CARD",
  "description": "Ticket purchase",
  "expiresAt": "2025-12-21T00:00:00"
}
```

#### Step 2: Get Payment Intent
```bash
curl -X GET "http://localhost:8080/v1/payments/intents/$INTENT_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

#### Step 3: Capture Payment (Process Payment)
```bash
# ⚠️ IMPORTANT: Reservation must be in PENDING state
# If you confirmed the reservation, create a new one

PAYMENT=$(curl -s -X POST "http://localhost:8080/v1/payments/intents/$INTENT_ID/capture" \
  -H "Authorization: Bearer $TOKEN")

PAYMENT_ID=$(echo $PAYMENT | jq -r '.paymentId')
echo "Payment ID: $PAYMENT_ID"
echo $PAYMENT | jq '.'
```

**Expected Response:**
```json
{
  "id": 1,
  "paymentId": "PAY-XXXXXXXX",
  "intentId": "PI-XXXXXXXX",
  "reservationId": "RES-XXXXXXXX",
  "userId": 1,
  "amount": 199.98,
  "currency": "USD",
  "status": "SUCCEEDED",
  "paymentMethod": "CARD"
}
```

**What happens during capture:**
- Payment is processed (simulated)
- Payment status updated to SUCCEEDED or FAILED
- Reservation is automatically confirmed
- Payment Intent status updated

### Testing Legacy Payment Flow

#### Create Payment Directly
```bash
# Create a new PENDING reservation first
NEW_RESERVATION=$(curl -s -X POST "http://localhost:8080/v1/reservations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "userId": 1,
    "eventId": '$EVENT_ID',
    "quantity": 1,
    "idempotencyKey": "legacy-pay-123"
  }')

NEW_RESERVATION_ID=$(echo $NEW_RESERVATION | jq -r '.reservationId')
NEW_RESERVATION_TOTAL=$(echo $NEW_RESERVATION | jq -r '.totalPrice')

# Create payment
PAYMENT=$(curl -s -X POST "http://localhost:8080/v1/payments" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "reservationId": "'$NEW_RESERVATION_ID'",
    "userId": 1,
    "amount": '$NEW_RESERVATION_TOTAL',
    "currency": "USD",
    "paymentMethod": "CARD",
    "description": "Ticket purchase",
    "idempotencyKey": "legacy-pay-123"
  }')

PAYMENT_ID=$(echo $PAYMENT | jq -r '.paymentId')
echo "Payment ID: $PAYMENT_ID"
```

### Other Payment Endpoints

#### Get All Payments
```bash
curl -X GET "http://localhost:8080/v1/payments" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

#### Get Payment by ID
```bash
curl -X GET "http://localhost:8080/v1/payments/$PAYMENT_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

#### Get User's Payments
```bash
curl -X GET "http://localhost:8080/v1/payments/user/1" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

#### Get User's Payment Intents
```bash
curl -X GET "http://localhost:8080/v1/payments/intents/user/1" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

#### Update Payment Status
```bash
curl -X PUT "http://localhost:8080/v1/payments/$PAYMENT_ID/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"status":"COMPLETED"}' | jq '.'
```

#### Process Payment
```bash
curl -X POST "http://localhost:8080/v1/payments/$PAYMENT_ID/process" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

#### Payment Service Health Check
```bash
curl -X GET "http://localhost:8080/v1/payments/ping" | jq '.'
```

#### Cleanup (Admin)
```bash
curl -X POST "http://localhost:8080/v1/payments/cleanup" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

## ⚠️ Important Notes

### Payment Amount Validation
- **The payment amount MUST match the reservation total exactly**
- If amounts don't match, you'll get: `"Payment amount X does not match reservation total Y"`

### Reservation State Requirements
- **Payment Intent Capture**: Reservation must be in `PENDING` state
- **Legacy Payment**: Reservation must be in `PENDING` state
- If reservation is already `CONFIRMED`, payment will fail

### Payment Processing
- Payment processing is **simulated** (not real payment gateway)
- Success rate is ~90% (randomized for testing)
- Failed payments will have status `FAILED`

### Idempotency
- Use unique `idempotencyKey` for each payment attempt
- Same key will return existing payment/intent (prevents duplicates)

## 🔍 Troubleshooting

### Error: "Payment amount does not match reservation total"
**Solution:** Get the exact reservation total and use it:
```bash
RESERVATION_TOTAL=$(curl -s "http://localhost:8080/v1/reservations/$RESERVATION_ID" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.totalPrice')
```

### Error: "Reservation is not in pending state"
**Solution:** Create a new reservation (don't confirm it before payment):
```bash
# Create new reservation
NEW_RESERVATION=$(curl -s -X POST "http://localhost:8080/v1/reservations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"userId":1,"eventId":'$EVENT_ID',"quantity":1,"idempotencyKey":"new-resv-123"}')
```

### Error: "Payment intent not found"
**Solution:** Use the `intentId` string (e.g., "PI-XXXXXXXX"), not the numeric ID

### Error: "Payment not found"
**Solution:** Use the `paymentId` string (e.g., "PAY-XXXXXXXX"), not the numeric ID

## 📊 Payment Status Flow

```
Payment Intent:
CREATED → REQUIRES_PAYMENT_METHOD → PROCESSING → SUCCEEDED/CANCELED

Payment:
PROCESSING → SUCCEEDED/FAILED
```

## 🎯 Testing Checklist

- [ ] Create user and get authentication token
- [ ] Create and publish an event
- [ ] Create a reservation (PENDING state)
- [ ] Create payment intent
- [ ] Get payment intent details
- [ ] Capture payment intent (process payment)
- [ ] Verify reservation is confirmed after payment
- [ ] Test legacy payment flow
- [ ] Get all payments
- [ ] Get user's payments
- [ ] Update payment status
- [ ] Process payment manually

## 📚 API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/v1/payments/intents` | Create payment intent |
| GET | `/v1/payments/intents/{intentId}` | Get payment intent |
| GET | `/v1/payments/intents/user/{userId}` | Get user's payment intents |
| POST | `/v1/payments/intents/{intentId}/capture` | Capture/process payment |
| POST | `/v1/payments` | Create payment (legacy) |
| GET | `/v1/payments` | Get all payments |
| GET | `/v1/payments/{paymentId}` | Get payment by ID |
| GET | `/v1/payments/user/{userId}` | Get user's payments |
| PUT | `/v1/payments/{paymentId}/status` | Update payment status |
| POST | `/v1/payments/{paymentId}/process` | Process payment |
| GET | `/v1/payments/ping` | Health check |
| POST | `/v1/payments/cleanup` | Cleanup (admin) |

