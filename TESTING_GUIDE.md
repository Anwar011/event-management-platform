# Testing Guide

## Prerequisites

Before starting, ensure you have:
1. ✅ Java 17 installed and active
2. ✅ Docker installed and running
3. ✅ PostgreSQL container running (see Docker Setup below)
4. ✅ Redis container running (optional, for API Gateway rate limiting)

## Docker Setup (Infrastructure)

### Quick Start
```bash
# Start PostgreSQL and Redis containers
./start-infrastructure.sh

# Or manually:
docker-compose -f docker-compose.dev.yml up -d
```

### Verify Containers
```bash
# Check running containers
docker ps

# Test PostgreSQL
docker exec postgres-user-dev pg_isready -U postgres

# Test Redis
docker exec redis-gateway-dev redis-cli ping
```

### Container Details
- **PostgreSQL**: `postgres-user-dev` on port `5432`
  - Database: `userdb`
  - User: `postgres` / Password: `postgres`
- **Redis**: `redis-gateway-dev` on port `6379`

See `DOCKER_SETUP.md` for detailed instructions.

## Service Startup Order

Services must be started in this order:
1. **Eureka Server** (Port 8761) - Service discovery registry
2. **Config Server** (Port 8888) - Configuration management
3. **User Service** (Port 8081) - User management & authentication
4. **API Gateway** (Port 8080) - Single entry point

## Expected Behavior

### 1. Eureka Server (Port 8761)
- **Startup**: Should start successfully
- **Dashboard**: Visit http://localhost:8761
- **Expected**: Eureka dashboard showing no registered services initially
- **After other services start**: Should show registered services (config-server, user-service, api-gateway)

### 2. Config Server (Port 8888)
- **Startup**: Should start and register with Eureka
- **Health Check**: http://localhost:8888/actuator/health
- **Expected**: Status "UP"
- **Eureka**: Should appear in Eureka dashboard

### 3. User Service (Port 8081)
- **Startup**: Should start, register with Eureka, and run Flyway migrations
- **Database**: Creates `users` and `user_roles` tables
- **Default Admin**: Creates admin user (admin@eventplatform.com / admin123)
- **Health Check**: http://localhost:8081/actuator/health
- **Expected**: Status "UP", database connection OK
- **Eureka**: Should appear in Eureka dashboard

### 4. API Gateway (Port 8080)
- **Startup**: Should start and register with Eureka
- **Health Check**: http://localhost:8080/actuator/health
- **Expected**: Status "UP"
- **Eureka**: Should appear in Eureka dashboard

## Testing Endpoints

### Test 1: User Registration
```bash
curl -X POST http://localhost:8080/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User"
  }'
```

**Expected Response:**
- Status: 201 Created
- Body: JSON with `token`, `userId`, `email`, `roles`
- Token should be a JWT string

### Test 2: User Login
```bash
curl -X POST http://localhost:8080/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

**Expected Response:**
- Status: 200 OK
- Body: JSON with `token`, `userId`, `email`, `roles`

### Test 3: Get Current User (Protected Endpoint)
```bash
# Use the token from registration/login
curl -X GET http://localhost:8080/v1/users/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Expected Response:**
- Status: 200 OK
- Body: User details (id, email, firstName, lastName, roles, etc.)

### Test 4: Access Protected Endpoint Without Token
```bash
curl -X GET http://localhost:8080/v1/users/me
```

**Expected Response:**
- Status: 401 Unauthorized
- No body (or error message)

### Test 5: Admin Login
```bash
curl -X POST http://localhost:8080/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@eventplatform.com",
    "password": "admin123"
  }'
```

**Expected Response:**
- Status: 200 OK
- Body: Token with `ROLE_ADMIN` in roles array

## Troubleshooting

### Service Won't Start
- Check if port is already in use: `lsof -i :PORT_NUMBER`
- Check Java version: `java -version` (should be 17)
- Check logs for specific errors

### Database Connection Issues
- Ensure PostgreSQL is running: `sudo systemctl status postgresql`
- Create database: `createdb userdb` (or via psql)
- Check connection settings in `application.yml`

### Eureka Registration Issues
- Ensure Eureka Server is running first
- Check service logs for registration errors
- Verify Eureka URL in `application.yml` matches Eureka Server port

### Gateway Routing Issues
- Check if services are registered in Eureka
- Verify gateway routes in `application.yml`
- Check gateway logs for routing errors

## Success Criteria

✅ All services start without errors
✅ All services appear in Eureka dashboard
✅ User registration works
✅ User login works
✅ JWT token is generated and valid
✅ Protected endpoints require authentication
✅ Gateway routes requests correctly

