# 💳 Frontend Payment Testing Guide

This guide explains how to test payment functionality through the web interface.

## 🚀 Quick Start

### Step 1: Access the Frontend
1. Make sure the frontend is running on `http://localhost:3001` (or check the port shown in terminal)
2. Open your browser and navigate to the frontend URL

### Step 2: Login or Register
1. Click **"Login"** or **"Register"** in the navigation
2. If registering, create a new account
3. If logging in, use existing credentials:
   - Email: `testuser@example.com`
   - Password: `password123`

### Step 3: Browse Events
1. Navigate to **"Events"** from the home page
2. Browse available events
3. Click on an event to view details

### Step 4: Create a Reservation
1. On the event detail page, select number of attendees
2. Click **"Book Now"** button
3. You'll be redirected to **"My Reservations"** page

### Step 5: Pay for Reservation
1. Go to **"My Reservations"** (from dashboard or navigation)
2. Find your **PENDING** reservation
3. Click the **"Pay Now"** button (green button with payment icon)
4. Confirm the payment in the popup
5. Wait for payment processing (you'll see "Processing..." indicator)
6. Success message will appear with Payment ID

### Step 6: View Payment History
1. Navigate to **"My Payments"** from the dashboard
2. You'll see all your payment transactions
3. View payment intents and completed payments

## 📋 Complete Testing Flow

### Full User Journey

```
1. Register/Login
   ↓
2. Browse Events
   ↓
3. View Event Details
   ↓
4. Book Event (Creates PENDING reservation)
   ↓
5. Go to My Reservations
   ↓
6. Click "Pay Now" on PENDING reservation
   ↓
7. Payment processed automatically
   ↓
8. Reservation status changes to CONFIRMED
   ↓
9. View payment in My Payments page
```

## 🎯 Testing Scenarios

### Scenario 1: Complete Payment Flow
1. **Create Reservation**
   - Go to Events page
   - Click on any published event
   - Select number of attendees
   - Click "Book Now"
   - ✅ Reservation created with PENDING status

2. **Make Payment**
   - Go to "My Reservations"
   - Find the PENDING reservation
   - Click "Pay Now" button
   - Confirm payment
   - ✅ Payment processed
   - ✅ Reservation status changes to CONFIRMED
   - ✅ Payment appears in "My Payments"

### Scenario 2: View Payment History
1. Navigate to **"My Payments"** page
2. View all payment transactions
3. See payment intents and completed payments
4. Check payment statuses (SUCCEEDED, FAILED, etc.)

### Scenario 3: Cancel Reservation
1. Go to "My Reservations"
2. Find a PENDING reservation
3. Click "Cancel" button
4. Confirm cancellation
5. ✅ Reservation status changes to CANCELLED

### Scenario 4: Multiple Reservations
1. Create multiple reservations for different events
2. Pay for some, leave others pending
3. View all reservations on "My Reservations" page
4. See which ones are paid (CONFIRMED) and which are pending

## 🔍 What to Check

### After Creating Reservation
- ✅ Reservation appears in "My Reservations"
- ✅ Status is "PENDING"
- ✅ Total amount is correct
- ✅ "Pay Now" button is visible

### After Payment
- ✅ Payment success message appears
- ✅ Reservation status changes to "CONFIRMED"
- ✅ "Pay Now" button disappears
- ✅ "✓ Paid" indicator appears
- ✅ Payment appears in "My Payments" page
- ✅ Payment status is "SUCCEEDED"

### Payment History Page
- ✅ All payments are listed
- ✅ Payment intents are shown
- ✅ Completed payments are shown
- ✅ Payment details are correct (amount, date, status)

## ⚠️ Common Issues & Solutions

### Issue: "Pay Now" button not showing
**Solution:** 
- Make sure reservation status is "PENDING"
- Refresh the page
- Check browser console for errors

### Issue: Payment fails
**Possible causes:**
- Reservation already confirmed (can't pay twice)
- Amount mismatch (shouldn't happen in UI)
- Network error

**Solution:**
- Check browser console for error details
- Try creating a new reservation
- Check API Gateway is running

### Issue: Payment stuck on "Processing..."
**Solution:**
- Wait a few seconds (payment processing takes time)
- Check browser console for errors
- Refresh the page if stuck for more than 30 seconds

### Issue: Reservation not updating after payment
**Solution:**
- Refresh the page
- Check "My Payments" to verify payment succeeded
- Reservation should auto-update, but manual refresh helps

## 🎨 UI Features to Test

### Reservation Card
- ✅ Shows reservation details
- ✅ Status badge (PENDING = yellow, CONFIRMED = green, CANCELLED = red)
- ✅ "Pay Now" button for PENDING reservations
- ✅ "Cancel" button for PENDING reservations
- ✅ "View Event" link
- ✅ Payment confirmation indicator for CONFIRMED

### Payment Page
- ✅ Lists all payment transactions
- ✅ Shows payment intents and payments
- ✅ Displays payment status
- ✅ Shows payment amounts and dates
- ✅ Empty state when no payments

## 📱 Testing Checklist

- [ ] Can register new user
- [ ] Can login with existing user
- [ ] Can browse events
- [ ] Can view event details
- [ ] Can create reservation
- [ ] Reservation appears in "My Reservations"
- [ ] Can see "Pay Now" button for PENDING reservations
- [ ] Can click "Pay Now" and see confirmation
- [ ] Payment processes successfully
- [ ] Reservation status updates to CONFIRMED
- [ ] Payment appears in "My Payments"
- [ ] Can view payment details
- [ ] Can cancel PENDING reservation
- [ ] Payment history shows all transactions

## 🔗 Navigation Paths

### From Home Page
```
Home → Events → [Event Detail] → Book Now → My Reservations → Pay Now
```

### From Dashboard
```
Dashboard → My Reservations → Pay Now
Dashboard → My Payments (view history)
```

### Direct Links
- `/events` - Browse all events
- `/events/:id` - View event details
- `/my-reservations` - View reservations (requires login)
- `/my-payments` - View payment history (requires login)

## 💡 Tips

1. **Use Browser DevTools**
   - Open Console (F12) to see API calls
   - Check Network tab to see request/response
   - Look for any errors

2. **Test Different Scenarios**
   - Single ticket purchase
   - Multiple tickets purchase
   - Multiple reservations
   - Cancel before paying
   - Pay after creating reservation

3. **Check Payment Status**
   - Payment can succeed or fail (simulated)
   - Check "My Payments" to see actual status
   - Failed payments will show failure reason

4. **Refresh After Actions**
   - After payment, refresh to see updated status
   - After cancellation, refresh to see changes
   - Data should auto-refresh, but manual refresh helps

## 🎯 Expected Behavior

### Payment Button States
- **PENDING reservation**: Green "Pay Now" button visible
- **CONFIRMED reservation**: "✓ Paid" indicator, no button
- **CANCELLED reservation**: No payment button

### Payment Processing
1. Click "Pay Now"
2. Confirmation dialog appears
3. Click "OK" to confirm
4. Button shows "Processing..." with spinner
5. Success message with Payment ID
6. Reservation updates to CONFIRMED
7. Payment appears in history

### Error Handling
- Network errors show user-friendly messages
- Payment failures show error details
- Invalid states prevent actions (e.g., can't pay confirmed reservation)

## 🚨 Troubleshooting

If payments aren't working:

1. **Check API Gateway is running**
   ```bash
   curl http://localhost:8080/actuator/health
   ```

2. **Check Frontend Console**
   - Open browser DevTools (F12)
   - Check Console for errors
   - Check Network tab for failed requests

3. **Verify Authentication**
   - Make sure you're logged in
   - Token should be in localStorage
   - Check if token is expired

4. **Check Reservation Status**
   - Only PENDING reservations can be paid
   - CONFIRMED reservations are already paid
   - CANCELLED reservations can't be paid

5. **Test API Directly**
   - Use the test scripts to verify backend works
   - If backend works but frontend doesn't, check CORS

## 📊 Success Indicators

✅ **Payment Successful:**
- Success alert with Payment ID
- Reservation status = CONFIRMED
- Payment appears in "My Payments"
- Payment status = SUCCEEDED

✅ **Payment Failed:**
- Error alert with reason
- Reservation stays PENDING
- Payment may appear in history with FAILED status

Now you're ready to test payments through the interface! 🎉

