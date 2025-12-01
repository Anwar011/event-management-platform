# EventHub Frontend

A modern, responsive web application for the Event Management Platform built with vanilla JavaScript, HTML5, and CSS3.

## 🚀 Features

- **User Authentication** - Register, login with JWT tokens
- **Event Discovery** - Browse, search, and filter events
- **Ticket Booking** - Real-time reservation system
- **User Dashboard** - Manage reservations and account
- **Responsive Design** - Works on desktop, tablet, and mobile
- **Modern UI** - Bootstrap 5 + custom styling
- **API Integration** - Connects to Spring Boot microservices

## 🏗️ Architecture

```
frontend-working/
├── index.html          # Main application
├── css/
│   └── styles.css      # Custom styles
├── js/
│   ├── app.js          # Main application logic
│   ├── auth.js         # Authentication handling
│   ├── events.js       # Event management
│   ├── reservations.js # Reservation system
│   └── ui.js           # UI interactions
└── README.md           # This file
```

## 🚀 Getting Started

### Prerequisites
- Modern web browser (Chrome, Firefox, Safari, Edge)
- Backend services running (see main project README)

### Running the Application

1. **Start the backend services:**
   ```bash
   ./start-demo-simple.sh
   ```

2. **Open the frontend:**
   ```bash
   # Method 1: Use a local server
   cd frontend-working
   python3 -m http.server 3000

   # Then open: http://localhost:3000

   # Method 2: Open directly in browser
   # Just open index.html in your browser
   # Note: Some features may not work due to CORS
   ```

### Backend API Endpoints

The frontend connects to these backend services:
- **API Gateway:** `http://localhost:8080`
- **Auth Service:** `/v1/auth`
- **User Service:** `/v1/users`
- **Event Service:** `/v1/events`
- **Reservation Service:** `/v1/reservations`

## 🎯 User Experience Flow

1. **Homepage** - Introduction and feature overview
2. **Authentication** - Register/login with JWT
3. **Event Discovery** - Browse events with search/filter
4. **Event Details** - View event information and book tickets
5. **Dashboard** - Manage reservations and account

## 🔧 Technical Details

### Technologies Used
- **HTML5** - Semantic markup
- **CSS3** - Modern styling with Flexbox/Grid
- **JavaScript (ES6+)** - Modern JavaScript features
- **Bootstrap 5** - Responsive UI framework
- **Font Awesome** - Icons
- **Fetch API** - HTTP requests

### Key Features
- **SPA-like Navigation** - Client-side routing
- **JWT Authentication** - Secure token management
- **Real-time Updates** - Dynamic content loading
- **Responsive Design** - Mobile-first approach
- **Error Handling** - User-friendly error messages
- **Loading States** - Better UX with spinners

### Browser Support
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## 🧪 Testing the Frontend

### Automated Tests
```bash
# Test with backend running
./demo-safe.sh

# This runs authentication, event loading, and reservation tests
```

### Manual Testing

1. **Authentication:**
   - Register a new user
   - Login with credentials
   - Check JWT token storage

2. **Events:**
   - Browse event listings
   - Use search and filters
   - View event details
   - Book tickets (requires login)

3. **Reservations:**
   - View user reservations
   - Check booking status
   - Cancel reservations

### Demo Data

The frontend includes demo data that displays when the backend is unavailable:
- Sample events with different categories
- Mock user reservations
- Example booking flows

## 🔌 API Integration

### Authentication
```javascript
// Login
POST /v1/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}

// Register
POST /v1/auth/register
{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe"
}
```

### Events
```javascript
// Get all events
GET /v1/events

// Get event details
GET /v1/events/{id}

// Get event availability
GET /v1/events/{id}/availability
```

### Reservations
```javascript
// Create reservation
POST /v1/reservations
{
  "userId": 1,
  "eventId": 1,
  "quantity": 2,
  "idempotencyKey": "unique-key"
}

// Get user reservations
GET /v1/reservations/user/{userId}

// Confirm reservation
POST /v1/reservations/{id}/confirm

// Cancel reservation
POST /v1/reservations/{id}/cancel
```

## 🐛 Troubleshooting

### Common Issues

1. **CORS Errors**
   - Make sure backend is running on `http://localhost:8080`
   - Check browser console for CORS policy errors

2. **Authentication Fails**
   - Verify backend auth service is running
   - Check JWT token storage in browser dev tools

3. **Events Not Loading**
   - Backend event service may be down
   - Frontend falls back to demo data automatically

4. **Booking Fails**
   - User must be logged in
   - Check reservation service status

### Debug Mode

Open browser developer tools (F12) to see:
- Network requests and responses
- JavaScript console logs
- Local storage (for JWT tokens)

## 🚀 Production Deployment

For production deployment:

1. **Build Optimization:**
   - Minify CSS/JavaScript
   - Optimize images
   - Enable compression

2. **API Configuration:**
   - Update API_BASE URLs
   - Configure CORS policies
   - Set up HTTPS

3. **Performance:**
   - Implement caching strategies
   - Use CDN for static assets
   - Enable service workers

4. **Security:**
   - Implement CSP headers
   - Use HTTPS only
   - Validate all inputs

## 📝 Contributing

1. Follow the existing code structure
2. Use ES6+ features
3. Add comments for complex logic
4. Test on multiple browsers
5. Follow responsive design principles

## 📄 License

This project is part of the Event Management Platform demonstration.


