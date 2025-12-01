# Docker Setup Guide

## Starting Docker

The Docker daemon needs to be running. Try one of these:

### Option 1: Start Docker Service
```bash
sudo systemctl start docker
sudo systemctl enable docker  # Enable auto-start on boot
```

### Option 2: If using Docker Desktop
```bash
# Start Docker Desktop application
# Or check if it's running in the background
```

### Verify Docker is Running
```bash
docker ps
# Should show running containers or empty list (not an error)
```

## Starting PostgreSQL Container

Once Docker is running, start the containers:

```bash
# Start PostgreSQL and Redis for development
cd /home/anwar/event-management-platform
docker-compose -f docker-compose.dev.yml up -d

# Check container status
docker ps

# View logs
docker-compose -f docker-compose.dev.yml logs -f postgres-user

# Stop containers
docker-compose -f docker-compose.dev.yml down

# Stop and remove volumes (clean slate)
docker-compose -f docker-compose.dev.yml down -v
```

## Container Details

### PostgreSQL (User Service)
- **Container**: `postgres-user-dev`
- **Port**: `5432` (host) → `5432` (container)
- **Database**: `userdb`
- **User**: `postgres`
- **Password**: `postgres`
- **Health Check**: `docker exec postgres-user-dev pg_isready -U postgres`

### Redis (API Gateway)
- **Container**: `redis-gateway-dev`
- **Port**: `6379` (host) → `6379` (container)
- **Health Check**: `docker exec redis-gateway-dev redis-cli ping`

## Testing Connection

Once containers are running, test the connection:

```bash
# Test PostgreSQL connection
docker exec postgres-user-dev psql -U postgres -d userdb -c "SELECT version();"

# Test Redis connection
docker exec redis-gateway-dev redis-cli ping
# Should return: PONG
```

## Troubleshooting

### Docker Permission Issues
If you get permission denied:
```bash
sudo usermod -aG docker $USER
# Log out and log back in, or:
newgrp docker
```

### Port Already in Use
If port 5432 is already in use:
```bash
# Check what's using the port
sudo lsof -i :5432

# Or change the port mapping in docker-compose.dev.yml
ports:
  - "5433:5432"  # Use 5433 on host instead
```

### Container Won't Start
```bash
# Check logs
docker-compose -f docker-compose.dev.yml logs postgres-user

# Remove and recreate
docker-compose -f docker-compose.dev.yml down -v
docker-compose -f docker-compose.dev.yml up -d
```

## Next Steps

After PostgreSQL is running:
1. Restart User Service - it should connect to the database
2. User Service will run Flyway migrations automatically
3. Default admin user will be created
4. Service will register with Eureka
5. Start API Gateway to complete the setup



