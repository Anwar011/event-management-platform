# Event Management Platform

A scalable microservices-based event management platform built with Spring Cloud, featuring event booking, reservations, and payment processing.

## 🏗️ Architecture Overview

This platform follows a microservices architecture with the following components:

### Infrastructure Services
- **Eureka Server** (Port 8761): Service discovery and registry
- **Config Server** (Port 8888): Centralized configuration management
- **API Gateway** (Port 8080): Single entry point with routing, JWT validation, CORS, and rate limiting

### Business Services
- **User Service** (Port 8081): User management and JWT authentication
- **Event Service** (Port 8082): Event CRUD operations and capacity management
- **Reservation Service** (Port 8083): Ticket reservations with limits and capacity checks
- **Payment Service** (Port 8084): Payment intent and capture flow
- **Notification Service** (Port 8085): Email/SMS notifications

### Frontend
- **React Frontend** (Port 3001): Modern React application with TypeScript, Vite, and Tailwind CSS

### Shared Components.
- **Common Library**: Shared DTOs, error models, and utilities

## 🛠️ Technology Stack

### Backend
- **Java 17**
- **Spring Boot 3.2.0**
- **Spring Cloud 2023.0.0**
- **PostgreSQL** (per-service database)
- **Flyway** (database migrations)
- **JWT** (authentication)
- **Resilience4j** (circuit breaking, retries, bulkheads)
- **Eureka** (service discovery)
- **Spring Cloud Gateway** (API gateway)
- **Redis** (rate limiting)

### Frontend
- **React 18** with TypeScript
- **Vite** (build tool)
- **Tailwind CSS** (styling)
- **React Query** (data fetching)
- **Axios** (HTTP client)

## 📁 Project Structure

```
event-management-platform/
├── eureka-server/          # Service discovery
├── config-server/          # Configuration server
├── api-gateway/            # API Gateway
├── common-lib/             # Shared DTOs and utilities
├── user-service/           # User management & auth
├── event-service/          # Event management
├── reservation-service/   # Reservation management
├── payment-service/        # Payment processing
├── notification-service/   # Notifications
├── eventhub-pro-frontend/  # React frontend application
├── docker-compose.yml      # Docker Compose for infrastructure
├── docker-compose.dev.yml  # Development Docker Compose
└── pom.xml                 # Parent POM
```

## 🚀 Getting Started

### Prerequisites

- **Java 17+**
- **Maven 3.8+**
- **PostgreSQL 14+**
- **Redis** (for rate limiting in gateway)
- **Node.js 18+** and **npm** (for frontend)

### Quick Start with Docker Compose

1. **Start infrastructure services** (PostgreSQL, Redis):
   ```bash
   docker-compose -f docker-compose.dev.yml up -d
   ```

2. **Build the project**:
   ```bash
   mvn clean install
   ```

3. **Start backend services in order** (each in a separate terminal):
   ```bash
   # Terminal 1: Eureka Server
   cd eureka-server && mvn spring-boot:run
   
   # Terminal 2: Config Server
   cd config-server && mvn spring-boot:run
   
   # Terminal 3: User Service
   cd user-service && mvn spring-boot:run
   
   # Terminal 4: Event Service
   cd event-service && mvn spring-boot:run
   
   # Terminal 5: Reservation Service
   cd reservation-service && mvn spring-boot:run
   
   # Terminal 6: Payment Service
   cd payment-service && mvn spring-boot:run
   
   # Terminal 7: Notification Service
   cd notification-service && mvn spring-boot:run
   
   # Terminal 8: API Gateway
   cd api-gateway && mvn spring-boot:run
   ```

4. **Start the frontend**:
   ```bash
   cd eventhub-pro-frontend
   npm install
   npm run dev
   ```

5. **Access the application**:
   - Frontend: http://localhost:3001
   - API Gateway: http://localhost:8080
   - Eureka Dashboard: http://localhost:8761

### Manual Database Setup

If not using Docker Compose, create databases manually:

```sql
CREATE DATABASE userdb;
CREATE DATABASE eventdb;
CREATE DATABASE reservationdb;
CREATE DATABASE paymentdb;
CREATE DATABASE notificationdb;
```

### Start Redis

```bash
redis-server
# Or with Docker:
docker run -d -p 6379:6379 redis:alpine
```

## 📡 API Endpoints

All APIs are accessed through the API Gateway at `http://localhost:8080/v1`

### Authentication
- `POST /v1/auth/register` - Register new user
- `POST /v1/auth/login` - Login and get JWT token

### Users
- `GET /v1/users/me` - Get current user profile
- `GET /v1/users/{id}` - Get user by ID

### Events
- `GET /v1/events` - List all events (paginated)
- `GET /v1/events/{id}` - Get event by ID
- `POST /v1/events` - Create event (admin only)
- `PUT /v1/events/{id}` - Update event (admin only)
- `DELETE /v1/events/{id}` - Delete event (admin only)

### Reservations
- `GET /v1/reservations` - Get user's reservations
- `GET /v1/reservations/{reservationId}` - Get reservation by ID
- `POST /v1/reservations` - Create reservation
- `PUT /v1/reservations/{reservationId}` - Update reservation
- `DELETE /v1/reservations/{reservationId}` - Cancel reservation

### Payments
- `GET /v1/payments/user/{userId}` - Get user's payments
- `GET /v1/payments/{paymentId}` - Get payment by ID
- `POST /v1/payments/intents` - Create payment intent
- `POST /v1/payments/intents/{intentId}/capture` - Capture payment intent
- `GET /v1/payments/intents/user/{userId}` - Get user's payment intents

For detailed API documentation, see [SERVICE_ENDPOINTS.md](SERVICE_ENDPOINTS.md)

## ⚙️ Configuration

### Environment Variables

- `JWT_SECRET`: Secret key for JWT signing (default: provided in config)
- `DB_USER`: PostgreSQL username (default: postgres)
- `DB_PASSWORD`: PostgreSQL password (default: postgres)
- `CONFIG_REPO_URI`: Git repository URI for config server (optional)

### Default Admin User

- Email: `admin@eventplatform.com`
- Password: `admin123`
- Role: `ROLE_ADMIN`

### Database Configuration

Each service uses its own PostgreSQL database:
- User Service → `userdb`
- Event Service → `eventdb`
- Reservation Service → `reservationdb`
- Payment Service → `paymentdb`
- Notification Service → `notificationdb`

Database migrations are handled automatically by Flyway on service startup.

## 🎯 Features

### ✅ Implemented

- [x] Microservices architecture with Spring Cloud
- [x] Service discovery with Eureka
- [x] Centralized configuration with Config Server
- [x] API Gateway with JWT authentication
- [x] User authentication and authorization
- [x] Event management (CRUD operations)
- [x] Reservation system with capacity management
- [x] Payment processing (intent-based flow)
- [x] Notification service
- [x] React frontend with modern UI
- [x] CORS configuration
- [x] Rate limiting with Redis
- [x] Database migrations with Flyway
- [x] Docker Compose for infrastructure

### 🔄 Payment Flow

1. User creates a reservation for an event
2. Reservation is created with `PENDING` status
3. User creates a payment intent for the reservation
4. Payment intent is created with `REQUIRES_PAYMENT_METHOD` status
5. User captures the payment intent
6. Payment is processed and reservation is confirmed

## 🧪 Testing

### Backend Testing

Use curl or Postman to test the APIs. Example:

```bash
# Register a user
curl -X POST http://localhost:8080/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123","firstName":"John","lastName":"Doe"}'

# Login
curl -X POST http://localhost:8080/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Get events (with token)
curl http://localhost:8080/v1/events \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Frontend Testing

1. Start the frontend: `cd eventhub-pro-frontend && npm run dev`
2. Open http://localhost:3001
3. Register/Login
4. Browse events and create reservations
5. Process payments through the UI

## 📦 Building and Running

### Build All Services

```bash
mvn clean install
```

### Run Individual Services

```bash
cd <service-name>
mvn spring-boot:run
```

### Build Frontend

```bash
cd eventhub-pro-frontend
npm install
npm run build
```

## 🐳 Docker

### Infrastructure Services

```bash
docker-compose -f docker-compose.dev.yml up -d
```

This starts:
- PostgreSQL databases for all services
- Redis for rate limiting

### Full Stack (Future)

A complete Docker Compose setup for all services is planned.

## 📝 Development

### Code Structure

- Each service is a separate Maven module
- Services communicate via REST APIs through the API Gateway
- Service-to-service communication uses Eureka for service discovery
- Configuration is centralized in the Config Server

### Adding a New Service

1. Create a new Maven module in the parent POM
2. Add service to Eureka client configuration
3. Configure database and migrations
4. Add routes in API Gateway
5. Update this README

## 🔒 Security

- JWT-based authentication
- Password encryption with BCrypt
- CORS configuration for frontend
- Rate limiting on API Gateway
- Input validation on all endpoints

## 📚 Documentation

- [SERVICE_ENDPOINTS.md](SERVICE_ENDPOINTS.md) - Complete API endpoint documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - Detailed architecture documentation

## 🤝 Contributing

This is an educational project. Feel free to fork and modify as needed.

## 📄 License

This project is for educational purposes.

## 🆘 Troubleshooting

### Services not registering with Eureka

- Check that Eureka Server is running on port 8761
- Verify service configuration includes Eureka client
- Check network connectivity

### Database connection errors

- Verify PostgreSQL is running
- Check database credentials in application.yml
- Ensure databases are created

### Frontend CORS errors

- Verify API Gateway CORS configuration
- Check that frontend origin is allowed in CorsConfig.java
- Ensure API Gateway is running

### Payment processing fails

- Check that reservation exists and is in PENDING status
- Verify payment amount matches reservation total
- Check payment service logs for errors
