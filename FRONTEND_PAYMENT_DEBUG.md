# 🔍 Frontend Payment Data Debugging Guide

## Issue: Payment Summary Showing Zeros

If the Payment Summary is showing all zeros, follow these steps:

### Step 1: Check Browser Console
1. Open browser DevTools (F12)
2. Go to Console tab
3. Look for debug logs:
   - `User ID: X`
   - `Payments data: [...]`
   - `Payment Intents data: [...]`
   - `Summary calculation: {...}`

### Step 2: Verify User ID
The payment data is fetched based on the logged-in user's ID. Check:
- What User ID is shown in the console?
- Does this user have payment data?

**To test with user that has data:**
```bash
# Login with user ID 2 (has payment data)
Email: testuser@example.com
Password: password123
```

### Step 3: Check Network Requests
1. Open DevTools → Network tab
2. Refresh the Payments page
3. Look for these requests:
   - `GET /v1/payments/user/{userId}`
   - `GET /v1/payments/intents/user/{userId}`
4. Check the response:
   - Status code should be 200
   - Response should contain payment data

### Step 4: Verify API Endpoints
Test the API directly:

```bash
# Replace USER_ID with your logged-in user ID
USER_ID=2
TOKEN="your-jwt-token"

# Get payment intents
curl "http://localhost:8080/v1/payments/intents/user/$USER_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Get payments
curl "http://localhost:8080/v1/payments/user/$USER_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

### Step 5: Check Payment Status Values
The summary counts payments based on status:

**Completed Payments:**
- `SUCCEEDED`
- `COMPLETED`
- `CAPTURED`

**Pending Payments:**
- `PENDING`
- `CREATED`
- `REQUIRES_PAYMENT_METHOD`
- `PROCESSING`
- `REQUIRES_ACTION`
- `REQUIRES_CONFIRMATION`

### Step 6: Create Test Payment
If you have no payment data, create one:

1. Go to Events page
2. Book an event (creates reservation)
3. Go to My Reservations
4. Click "Pay Now" on a PENDING reservation
5. Payment will be processed
6. Go back to My Payments
7. Summary should now show data

### Step 7: Verify Data Format
Check if the API response matches expected format:

```javascript
// Expected Payment format:
{
  id: number,
  paymentId: string,
  status: "SUCCEEDED" | "FAILED" | "PENDING" | "PROCESSING",
  amount: number,
  currency: string,
  ...
}

// Expected PaymentIntent format:
{
  id: number,
  intentId: string,
  status: "REQUIRES_PAYMENT_METHOD" | "SUCCEEDED" | "CANCELED" | ...,
  amount: number,
  currency: string,
  ...
}
```

## Common Issues & Solutions

### Issue 1: User ID Mismatch
**Symptom:** Summary shows zeros but API has data for different user ID

**Solution:**
- Check console for logged User ID
- Login with the user that has payment data
- Or create payments for your current user

### Issue 2: API Errors
**Symptom:** Yellow warning banner appears

**Solution:**
- Check Network tab in DevTools
- Verify API Gateway is running
- Check CORS is configured correctly
- Verify authentication token is valid

### Issue 3: Status Not Matching
**Symptom:** Payments exist but not counted in summary

**Solution:**
- Check console for "Summary calculation" log
- Verify payment status values match expected values
- Check if status is null or undefined

### Issue 4: Amount Calculation Wrong
**Symptom:** Total Paid shows $0.00 but payments exist

**Solution:**
- Check if amount field exists in response
- Verify amount is a number, not string
- Check console for amount values

## Quick Test

Run this to verify your user has payment data:

```bash
# Get your user ID from browser console or localStorage
USER_ID=2  # Replace with your user ID

# Test API
curl "http://localhost:8080/v1/payments/intents/user/$USER_ID" | jq 'length'
curl "http://localhost:8080/v1/payments/user/$USER_ID" | jq 'length'
```

## Expected Behavior

### With Payment Data:
- Summary shows actual counts
- Completed: Number of SUCCEEDED payments
- Pending: Number of PENDING/REQUIRES_PAYMENT_METHOD payments
- Total Paid: Sum of completed payment amounts

### Without Payment Data:
- Summary shows zeros (correct behavior)
- Empty state message appears
- "Browse Events" button shown

## Debug Information

The page now includes:
- User ID display in header
- Debug info in development mode
- Console logs for all data
- Status breakdown in summary

Check browser console for detailed debugging information!

