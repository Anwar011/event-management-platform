# 🚀 Quick Frontend Payment Test

## Step-by-Step Guide

### 1. Open Frontend
```
http://localhost:3001
```

### 2. Login
- Click "Login" 
- Use: `testuser@example.com` / `password123`
- Or register a new account

### 3. Browse Events
- Click "Events" in navigation
- Click on any event card

### 4. Book Event
- Select number of attendees
- Click "Book Now" button
- ✅ Redirected to "My Reservations"

### 5. Pay for Reservation
- Find your **PENDING** reservation
- Click **"Pay Now"** button (green button)
- Confirm payment
- ✅ Payment processes
- ✅ Status changes to CONFIRMED

### 6. View Payment
- Go to "My Payments" from dashboard
- ✅ See your payment in history

## 🎯 What You'll See

### Before Payment
```
Reservation #123
Status: PENDING (yellow badge)
[Pay Now] [Cancel] [View Event]
```

### After Payment
```
Reservation #123
Status: CONFIRMED (green badge)
✓ Paid
[View Event]
```

## ⚡ Quick Test Commands

Check if frontend is running:
```bash
curl http://localhost:3001
```

Check if API is accessible:
```bash
curl http://localhost:8080/v1/payments/ping
```

## 📍 Navigation

**Dashboard** → **My Reservations** → **Pay Now**

Or direct URL:
```
http://localhost:3001/my-reservations
```

## ✅ Success Indicators

- Green "Pay Now" button visible on PENDING reservations
- Payment confirmation dialog appears
- "Processing..." indicator during payment
- Success message with Payment ID
- Reservation status changes to CONFIRMED
- Payment appears in "My Payments" page

That's it! 🎉
