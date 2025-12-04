# Event Management Platform - Architecture Documentation

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Architecture Overview](#architecture-overview)
- [Technology Stack](#technology-stack)
- [Service Architecture](#service-architecture)
- [Data Models & Relationships](#data-models--relationships)
- [API Specifications](#api-specifications)
- [Infrastructure Components](#infrastructure-components)
- [Security Implementation](#security-implementation)
- [Database Design](#database-design)
- [Deployment & Scaling](#deployment--scaling)
- [Development Workflow](#development-workflow)
- [Current Implementation Status](#current-implementation-status)

## 🎯 Project Overview

The **Event Management Platform** is a scalable, cloud-native microservices-based system designed to manage event ticketing, reservations, and payments. The platform provides a complete solution for event organizers to create events, manage ticket sales, handle reservations, and process payments, while offering users a seamless experience for discovering and booking events.

### Key Features
- **Event Management**: Create, update, and manage events with capacity limits
- **Ticket Reservations**: Real-time reservation system with capacity constraints
- **Payment Processing**: Secure payment intent and capture flow
- **User Authentication**: JWT-based authentication and authorization
- **Notification System**: Email/SMS notifications for booking confirmations
- **Scalable Architecture**: Microservices with service discovery and load balancing
- **Centralized Configuration**: Environment-agnostic configuration management
- **Observability**: Health monitoring and metrics collection

## 🏗️ Architecture Overview

### Microservices Architecture Pattern
The platform follows a **microservices architecture** where each business domain is implemented as an independent service. Services communicate through REST APIs and are orchestrated through an API Gateway.

### Key Architectural Patterns Used
- **Service Discovery**: Eureka Server for dynamic service registration/discovery
- **API Gateway**: Spring Cloud Gateway for routing, authentication, and load balancing
- **Centralized Configuration**: Spring Cloud Config Server for environment management
- **Database per Service**: Each service owns its data with appropriate consistency patterns
- **Event-Driven Communication**: Asynchronous messaging for cross-service communication
- **Circuit Breaker**: Resilience4j for fault tolerance
- **JWT Authentication**: Stateless authentication with signed tokens

### System Components
```
┌─────────────────────────────────────────────────────────────┐
│                    Client Applications                      │
│  (Web, Mobile, Third-party integrations)                   │
└─────────────────────┬───────────────────────────────────────┘
                      │
           ┌──────────▼──────────┐
           │   API Gateway       │
           │   (Port: 8080)      │
           │                     │
           │ • Route Management  │
           │ • JWT Validation    │
           │ • Rate Limiting     │
           │ • Load Balancing    │
           └──────────┬──────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
┌───────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
│User Service │ │Event      │ │Reservation│
│(Port: 8081) │ │Service    │ │Service    │
│             │ │(Port: 8082)│ │(Port: 8083)│
│• Auth       │ │• CRUD     │ │• Bookings │
│• JWT        │ │• Capacity │ │• Limits   │
│• Profiles   │ │• Search   │ │• Capacity │
└─────────────┘ └───────────┘ └───────────┘
        │             │             │
        └─────────────┼─────────────┘
                     │
        ┌────────────▼────────────┐
        │      Payment Service    │
        │      (Port: 8084)       │
        │                         │
        │ • Payment Intents       │
        │ • Payment Capture       │
        │ • Status Tracking       │
        └─────────────┬────────────┘
                     │
        ┌────────────▼────────────┐
        │  Notification Service   │
        │      (Port: 8085)       │
        │                         │
        │ • Email Notifications   │
        │ • SMS Notifications     │
        │ • Template Management   │
        └─────────────────────────┘

Infrastructure Layer:
• Eureka Server (Port: 8761) - Service Discovery
• Config Server (Port: 8888) - Configuration Management
• PostgreSQL Database - Per-service data storage
• Redis - Caching and rate limiting
```

## 🛠️ Technology Stack

### Core Framework
- **Java 17**: Programming language with LTS support
- **Spring Boot 3.2.0**: Framework for building microservices
- **Spring Cloud 2023.0.0**: Cloud-native patterns and tools

### Service Architecture
- **Spring Web MVC**: REST API development
- **Spring Data JPA**: Data access layer
- **Spring Security**: Authentication and authorization
- **Spring Cloud Netflix Eureka**: Service discovery
- **Spring Cloud Gateway**: API Gateway and routing
- **Spring Cloud Config**: Centralized configuration

### Database & Caching
- **PostgreSQL 15**: Relational database per service
- **Flyway**: Database migration management
- **Redis**: In-memory caching and session storage
- **HikariCP**: Connection pooling

### Observability & Monitoring
- **Spring Boot Actuator**: Health checks and metrics
- **Micrometer**: Metrics collection
- **SLF4J + Logback**: Structured logging
- **Correlation IDs**: Request tracing across services

### Development Tools
- **Maven**: Build automation and dependency management
- **Lombok**: Code generation for boilerplate reduction
- **JUnit 5**: Unit testing framework
- **Testcontainers**: Integration testing with Docker
- **Docker & Docker Compose**: Containerization and orchestration

### Security
- **JWT (JSON Web Tokens)**: Stateless authentication
- **BCrypt**: Password hashing
- **Spring Security**: Framework integration
- **CORS**: Cross-origin resource sharing configuration

## 🏛️ Service Architecture

### 1. User Service (Port: 8081)
**Responsibilities:**
- User registration and profile management
- JWT token generation and validation
- Password hashing and security
- User authentication and authorization

**Key Endpoints:**
- `POST /auth/register` - User registration
- `POST /auth/login` - User authentication
- `GET /users/me` - Current user profile
- `GET /users/{id}` - User profile by ID

**Database:** PostgreSQL (`userdb`)

### 2. Event Service (Port: 8082)
**Responsibilities:**
- Event CRUD operations
- Capacity management and validation
- Event search and filtering
- Organizer management

**Key Endpoints:**
- `POST /events` - Create event
- `GET /events` - List events with filters
- `GET /events/{id}` - Get event details
- `PUT /events/{id}` - Update event
- `DELETE /events/{id}` - Delete event
- `GET /events/{id}/availability` - Check ticket availability

**Database:** PostgreSQL (`eventdb`)

### 3. Reservation Service (Port: 8083)
**Responsibilities:**
- Ticket reservation management
- Capacity constraint enforcement
- Per-user booking limits
- Reservation status tracking
- Idempotency key handling

**Key Endpoints:**
- `POST /reservations` - Create reservation
- `GET /reservations/{id}` - Get reservation details
- `POST /reservations/{id}/confirm` - Confirm reservation
- `POST /reservations/{id}/cancel` - Cancel reservation

**Database:** PostgreSQL (`reservationdb`)

### 4. Payment Service (Port: 8084)
**Responsibilities:**
- Payment intent creation
- Payment capture and processing
- Payment status tracking
- Transaction history
- Integration with payment providers

**Key Endpoints:**
- `POST /payments/intents` - Create payment intent
- `POST /payments/{id}/capture` - Capture payment
- `GET /payments/{id}` - Get payment status

**Database:** PostgreSQL (`paymentdb`)

### 5. Notification Service (Port: 8085)
**Responsibilities:**
- Email and SMS notifications
- Template management
- Event-driven notifications
- Delivery tracking

**Key Endpoints:**
- `POST /notify/reservation` - Send reservation confirmation
- `POST /notify/payment` - Send payment confirmation

**Database:** PostgreSQL (`notificationdb`)

## 💾 Data Models & Relationships

### User Service Data Model
```sql
-- Users table
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) NOT NULL DEFAULT 'ROLE_USER',
    status VARCHAR(20) DEFAULT 'ACTIVE'
);
```

### Event Service Data Model
```sql
-- Events table
CREATE TABLE events (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(50) NOT NULL,
    venue VARCHAR(255),
    address TEXT,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    organizer_id BIGINT NOT NULL,
    status VARCHAR(20) DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Event capacity tracking
CREATE TABLE event_capacity (
    event_id BIGINT PRIMARY KEY REFERENCES events(id),
    total_capacity INTEGER NOT NULL,
    reserved_capacity INTEGER DEFAULT 0,
    available_capacity INTEGER GENERATED ALWAYS AS (total_capacity - reserved_capacity) STORED
);
```

### Reservation Service Data Model
```sql
-- Reservations table
CREATE TABLE reservations (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    event_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    idempotency_key VARCHAR(255) UNIQUE,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reservation items (if multiple tickets per reservation)
CREATE TABLE reservation_items (
    id BIGSERIAL PRIMARY KEY,
    reservation_id BIGINT NOT NULL REFERENCES reservations(id),
    ticket_type VARCHAR(50),
    price DECIMAL(10,2) NOT NULL,
    quantity INTEGER NOT NULL
);
```

### Payment Service Data Model
```sql
-- Payment intents
CREATE TABLE payment_intents (
    id BIGSERIAL PRIMARY KEY,
    reservation_id BIGINT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'PENDING',
    provider_reference VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payment transactions
CREATE TABLE payment_transactions (
    id BIGSERIAL PRIMARY KEY,
    payment_intent_id BIGINT NOT NULL REFERENCES payment_intents(id),
    amount DECIMAL(10,2) NOT NULL,
    transaction_type VARCHAR(20), -- CAPTURE, REFUND, etc.
    status VARCHAR(20),
    provider_transaction_id VARCHAR(255),
    processed_at TIMESTAMP
);
```

### Cross-Service Relationships
- **User ↔ Reservation**: One-to-many (user can have multiple reservations)
- **Event ↔ Reservation**: One-to-many (event can have multiple reservations)
- **Reservation ↔ Payment**: One-to-one (each reservation has one payment)
- **Event ↔ User**: Many-to-one (events belong to organizers)

## 🔌 API Specifications

### Authentication Flow
```
1. User Registration:
POST /v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe"
}

Response: 201 Created
{
  "token": "eyJhbGciOiJIUzUxMiJ9...",
  "userId": 1,
  "email": "user@example.com",
  "roles": ["ROLE_USER"]
}

2. User Login:
POST /v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}

Response: 200 OK
{
  "token": "eyJhbGciOiJIUzUxMiJ9...",
  "userId": 1,
  "email": "user@example.com",
  "roles": ["ROLE_USER"]
}
```

### Event Management Flow
```
1. Create Event:
POST /v1/events
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "title": "Tech Conference 2024",
  "description": "Annual technology conference",
  "eventType": "CONFERENCE",
  "venue": "Convention Center",
  "startDate": "2024-06-15T09:00:00Z",
  "capacity": 500,
  "price": 99.99
}

2. Check Availability:
GET /v1/events/1/availability
Authorization: Bearer <jwt-token>

Response: 200 OK
{
  "eventId": 1,
  "totalCapacity": 500,
  "availableCapacity": 450,
  "reservedCapacity": 50
}
```

### Reservation Flow
```
1. Create Reservation:
POST /v1/reservations
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "eventId": 1,
  "quantity": 2,
  "idempotencyKey": "unique-key-123"
}

Response: 201 Created
{
  "reservationId": 1,
  "eventId": 1,
  "quantity": 2,
  "totalPrice": 199.98,
  "status": "PENDING",
  "expiresAt": "2024-06-01T10:00:00Z"
}

2. Confirm Reservation (after payment):
POST /v1/reservations/1/confirm
Authorization: Bearer <jwt-token>
```

### Payment Flow
```
1. Create Payment Intent:
POST /v1/payments/intents
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "reservationId": 1,
  "amount": 199.98
}

Response: 201 Created
{
  "paymentIntentId": 1,
  "clientSecret": "pi_secret_...",
  "amount": 199.98,
  "status": "REQUIRES_PAYMENT_METHOD"
}

2. Capture Payment:
POST /v1/payments/1/capture
Authorization: Bearer <jwt-token>

Response: 200 OK
{
  "paymentIntentId": 1,
  "status": "SUCCEEDED",
  "capturedAmount": 199.98
}
```

## 🏢 Infrastructure Components

### Eureka Server (Port: 8761)
**Purpose:** Service discovery and registration
**Configuration:**
- Service registration on startup
- Health check monitoring
- Load balancing support
- Service instance tracking

### Config Server (Port: 8888)
**Purpose:** Centralized configuration management
**Features:**
- Environment-specific configurations
- Git-backed configuration (extensible)
- Native filesystem fallback
- Runtime configuration refresh
- Encrypted sensitive data support

### API Gateway (Port: 8080)
**Purpose:** Single entry point for all client requests
**Features:**
- Route management and forwarding
- JWT token validation
- Rate limiting and throttling
- CORS configuration
- Request/response transformation
- Circuit breaker integration

### Database Infrastructure
**PostgreSQL Setup:**
- Separate database per service
- Connection pooling with HikariCP
- Flyway migrations for schema evolution
- Backup and recovery procedures

**Redis Setup:**
- Session storage (if needed)
- Rate limiting data
- Caching layer for performance
- Pub/Sub for notifications

## 🔐 Security Implementation

### JWT Authentication
**Token Structure:**
```json
{
  "alg": "HS512",
  "typ": "JWT"
}
{
  "sub": "user-id",
  "email": "user@example.com",
  "roles": ["ROLE_USER"],
  "iat": 1640995200,
  "exp": 1641081600
}
```

**Security Features:**
- HS512 algorithm for signing
- Configurable expiration (24 hours default)
- Role-based authorization
- Stateless authentication
- Secure token storage

### API Gateway Security
**Request Flow:**
```
Client Request → API Gateway → JWT Validation → Route to Service
                      ↓
               401 Unauthorized (invalid/missing token)
                      ↓
               403 Forbidden (insufficient permissions)
                      ↓
               200 OK (authorized)
```

**Security Filters:**
- **JwtAuthenticationFilter**: Validates JWT tokens
- **CorrelationIdFilter**: Adds request tracing IDs
- **Rate Limiting**: Prevents abuse (configurable)
- **CORS**: Configured for web clients

### Service-Level Security
**Spring Security Configuration:**
- Stateless session management
- CSRF disabled for API endpoints
- Public endpoints: `/auth/**`, `/actuator/**`
- Protected endpoints require valid JWT

### Data Security
- **Passwords**: BCrypt hashing with salt
- **Database**: Parameterized queries prevent SQL injection
- **HTTPS**: SSL/TLS encryption in production
- **Secrets**: Environment variables for sensitive data

## 🗄️ Database Design

### Database per Service Pattern
Each service maintains its own database to ensure:
- **Loose Coupling**: Services can evolve independently
- **Technology Diversity**: Different databases if needed
- **Scalability**: Independent scaling of data tiers
- **Fault Isolation**: Database issues contained to one service

### Schema Evolution
**Flyway Migrations:**
- Version-controlled schema changes
- Automatic migration on startup
- Rollback support for development
- Environment-specific migrations

### Data Consistency
**Saga Pattern for Distributed Transactions:**
```
Reservation Creation Saga:
1. Reserve capacity in Event Service
2. Create reservation in Reservation Service
3. Create payment intent in Payment Service
4. Send confirmation notification

Compensation:
- Release capacity if payment fails
- Cancel reservation if notification fails
```

### Indexing Strategy
**Performance Optimization:**
- Primary keys on all tables
- Foreign key indexes
- Email uniqueness constraints
- Status and date-based indexes
- Composite indexes for common queries

## 🚀 Deployment & Scaling

### Docker Containerization
**Multi-stage Builds:**
```dockerfile
# Build stage
FROM maven:3.9.4-openjdk-17-slim AS build
COPY . .
RUN mvn clean package -DskipTests

# Runtime stage
FROM openjdk:17-jre-slim
COPY --from=build target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
```

### Docker Compose for Development
**Complete Stack:**
```yaml
version: '3.8'
services:
  eureka-server:
    image: event-platform/eureka-server:latest
    ports: ["8761:8761"]

  config-server:
    image: event-platform/config-server:latest
    ports: ["8888:8888"]

  api-gateway:
    image: event-platform/api-gateway:latest
    ports: ["8080:8080"]

  user-service:
    image: event-platform/user-service:latest
    ports: ["8081:8081"]
    depends_on: [postgres, redis]

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: eventplatform
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres

  redis:
    image: redis:7-alpine
```

### Kubernetes Deployment
**Microservices on K8s:**
- **Deployments**: Rolling updates and scaling
- **Services**: Load balancing and discovery
- **ConfigMaps**: Environment-specific configurations
- **Secrets**: Secure credential management
- **Ingress**: External access and SSL termination

### Horizontal Scaling
**Service Scaling Strategies:**
- **Stateless Services**: API Gateway, User Service (easy scaling)
- **Stateful Services**: Database services with persistent volumes
- **Load Balancing**: Kubernetes services distribute traffic
- **Auto-scaling**: HPA based on CPU/memory metrics

## 🔄 Development Workflow

### Local Development Setup
```bash
# Start infrastructure
docker-compose -f docker-compose.dev.yml up -d

# Start services in order
./mvnw spring-boot:run -pl eureka-server
./mvnw spring-boot:run -pl config-server
./mvnw spring-boot:run -pl api-gateway
./mvnw spring-boot:run -pl user-service
```

### Testing Strategy
**Test Pyramid:**
- **Unit Tests**: Service layer business logic
- **Integration Tests**: API endpoints with Testcontainers
- **Contract Tests**: API compatibility between services
- **End-to-End Tests**: Full user journeys

**Testing Tools:**
- **JUnit 5**: Unit testing framework
- **Testcontainers**: Docker-based integration tests
- **RestAssured**: API testing DSL
- **WireMock**: Service virtualization

### CI/CD Pipeline
**GitHub Actions Workflow:**
```yaml
name: CI/CD Pipeline
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      - name: Run tests
        run: ./mvnw test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Build Docker images
        run: docker build -t event-platform/${{ matrix.service }} .
      - name: Push to registry
        run: docker push event-platform/${{ matrix.service }}
```

### Code Quality
**Quality Gates:**
- **SonarQube**: Code quality and security analysis
- **JaCoCo**: Code coverage reporting (target: 80%)
- **SpotBugs**: Static code analysis
- **Checkstyle**: Code formatting validation

## 📊 Current Implementation Status

### ✅ Completed Components
- [x] **Maven Multi-module Structure**
- [x] **Eureka Service Discovery**
- [x] **Config Server (Native Mode)**
- [x] **API Gateway with Routing**
- [x] **User Service with JWT Authentication**
- [x] **Database Design & Migrations**
- [x] **Security Implementation**
- [x] **Docker Containerization**
- [x] **Comprehensive Testing Suite**

### 🚧 Pending Components
- [ ] **Event Service**: CRUD operations, capacity management
- [ ] **Reservation Service**: Booking logic, limits, idempotency
- [ ] **Payment Service**: Intent/capture flow, provider integration
- [ ] **Notification Service**: Email/SMS, templates, events
- [ ] **Resilience4j**: Circuit breakers, retries, bulkheads
- [ ] **Monitoring**: Prometheus, Grafana dashboards
- [ ] **Production Deployment**: Kubernetes manifests
- [ ] **Frontend**: React/Angular client application

### 🎯 Key Achievements
1. **Solid Architecture**: Microservices with proper separation of concerns
2. **Production-Ready**: Comprehensive error handling and logging
3. **Scalable Design**: Horizontal scaling support built-in
4. **Security First**: JWT authentication and authorization
5. **Developer Experience**: Hot reload, comprehensive testing, documentation
6. **Cloud-Native**: Containerized, orchestrated, observable

### 🚀 Next Development Phase
**Priority Order:**
1. **Event Service** - Core business functionality
2. **Reservation Service** - Revenue-generating feature
3. **Payment Integration** - Monetization capability
4. **Notification System** - User experience enhancement
5. **Observability Stack** - Production monitoring

---

**This architecture provides a robust, scalable foundation for a production-grade event management platform. The microservices design ensures maintainability, the security implementation protects user data, and the infrastructure components enable seamless scaling and deployment.**

**For questions or contributions, please refer to the individual service README files or create an issue in the project repository.** 📚



