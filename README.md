# Event Management Platform

A scalable microservices-based event management platform built with Spring Cloud.

## Architecture Overview

This platform follows a microservices architecture with the following components:

### Infrastructure Services
- **Eureka Server** (Port 8761): Service discovery and registry
- **Config Server** (Port 8888): Centralized configuration management
- **API Gateway** (Port 8080): Single entry point with routing, JWT validation, and rate limiting

### Business Services
- **User Service** (Port 8081): User management and JWT authentication
- **Event Service** (Port 8082): Event CRUD operations and capacity management
- **Reservation Service** (Port 8083): Ticket reservations with limits and capacity checks
- **Payment Service** (Port 8084): Payment intent and capture flow
- **Notification Service** (Port 8085): Email/SMS notifications

### Shared Components
- **Common Library**: Shared DTOs, error models, and utilities

## Technology Stack

- **Java 17**
- **Spring Boot 3.2.0**
- **Spring Cloud 2023.0.0**
- **PostgreSQL** (per-service database)
- **Flyway** (database migrations)
- **JWT** (authentication)
- **Resilience4j** (circuit breaking, retries, bulkheads)
- **Eureka** (service discovery)
- **Spring Cloud Gateway** (API gateway)

## Project Structure

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
└── pom.xml                 # Parent POM
```

## Getting Started

### Prerequisites

- Java 17+
- Maven 3.8+
- PostgreSQL 14+
- Redis (for rate limiting in gateway)

### Setup Steps

1. **Start PostgreSQL** and create databases:
   ```sql
   CREATE DATABASE userdb;
   CREATE DATABASE eventdb;
   CREATE DATABASE reservationdb;
   CREATE DATABASE paymentdb;
   CREATE DATABASE notificationdb;
   ```

2. **Start Redis** (for API Gateway rate limiting):
   ```bash
   redis-server
   ```

3. **Build the project**:
   ```bash
   mvn clean install
   ```

4. **Start services in order**:
   ```bash
   # 1. Eureka Server
   cd eureka-server && mvn spring-boot:run

   # 2. Config Server
   cd config-server && mvn spring-boot:run

   # 3. User Service
   cd user-service && mvn spring-boot:run

   # 4. API Gateway
   cd api-gateway && mvn spring-boot:run

   # 5. Other services...
   ```

## API Endpoints

### Authentication (via Gateway: http://localhost:8080/v1/auth)

- `POST /v1/auth/register` - Register new user
- `POST /v1/auth/login` - Login and get JWT token

### User Service (via Gateway: http://localhost:8080/v1/users)

- `GET /v1/users/me` - Get current user profile
- `GET /v1/users/{id}` - Get user by ID

## Configuration

### Environment Variables

- `JWT_SECRET`: Secret key for JWT signing (default: provided in config)
- `DB_USER`: PostgreSQL username (default: postgres)
- `DB_PASSWORD`: PostgreSQL password (default: postgres)
- `CONFIG_REPO_URI`: Git repository URI for config server (optional)

### Default Admin User

- Email: `admin@eventplatform.com`
- Password: `admin123`
- Role: `ROLE_ADMIN`

## Development Status

### ✅ Completed
- [x] Maven multi-module structure
- [x] Eureka Server setup
- [x] Config Server setup
- [x] API Gateway with JWT authentication
- [x] Common library with shared DTOs
- [x] User Service with full authentication

### 🚧 In Progress
- [ ] Event Service
- [ ] Reservation Service
- [ ] Payment Service
- [ ] Notification Service
- [ ] Resilience4j integration
- [ ] Docker Compose setup

## Next Steps

1. Implement Event Service with CRUD and capacity management
2. Implement Reservation Service with limits and idempotency
3. Implement Payment Service with intent/capture flow
4. Implement Notification Service
5. Add Resilience4j circuit breakers and retries
6. Set up observability (Prometheus, Grafana)
7. Create Docker Compose for local development

## License

This project is for educational purposes.



