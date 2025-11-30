# Event Management Platform - Demo Script Usage

## Quick Start

Run the complete demonstration:
```bash
./demo-platform.sh
```

## Selective Demonstrations

### Quick Health Check Only
```bash
./demo-platform.sh quick
```

### Authentication Demo Only
```bash
./demo-platform.sh auth
```

### Complete Workflow Demo
```bash
./demo-platform.sh workflow
```

## What the Script Does

1. **Infrastructure Check** - Verifies PostgreSQL and Redis are running
2. **Service Health** - Tests all 7 microservices health endpoints
3. **Architecture Overview** - Shows platform components and features
4. **Live Demonstrations**:
   - User registration and JWT authentication
   - Event creation and management
   - Ticket reservation system
   - Payment processing workflow
5. **Results Summary** - Shows test statistics and platform status

## Prerequisites

- Docker running with PostgreSQL and Redis containers
- All microservices started and registered with Eureka
- Java 17 installed

## Expected Output

The script provides:
- ✅ Color-coded test results (green = pass, red = fail)
- 📊 Real-time API call demonstrations
- 🏗️ Architecture explanations
- 📈 Success rate and metrics

## Perfect for Stakeholders

This script is designed to impress stakeholders by:
- Showing the complete system working end-to-end
- Demonstrating real business functionality
- Proving scalability and reliability
- Providing clear, professional output
