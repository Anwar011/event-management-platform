# Service Endpoints

Testing notes:
- Replace `<EVENT_SERVICE_URL>`, `<RESERVATION_SERVICE_URL>`, `<PAYMENT_SERVICE_URL>`, `<USER_SERVICE_URL>` with the actual base URLs (for example `http://localhost:8080`).

## event-service

Base path: `/events`

- `GET /events/ping`  
  Test: `curl -X GET "<EVENT_SERVICE_URL>/events/ping"`
- `POST /events`  
  Test: `curl -X POST "<EVENT_SERVICE_URL>/events" -H "Content-Type: application/json" -d '{"title":"Sample Conference","description":"A great tech event","eventType":"CONFERENCE","venue":"Main Hall","address":"123 Main St","city":"Berlin","state":"BE","country":"DE","postalCode":"10115","startDate":"2030-01-01T10:00:00","endDate":"2030-01-01T18:00:00","capacity":100,"price":49.99,"organizerId":1}'`
- `GET /events/{eventId}`  
  Test: `curl -X GET "<EVENT_SERVICE_URL>/events/1"`
- `PUT /events/{eventId}`  
  Test: `curl -X PUT "<EVENT_SERVICE_URL>/events/1" -H "Content-Type: application/json" -d '{"title":"Updated Conference","description":"Updated description","eventType":"CONFERENCE","venue":"Main Hall 2","address":"456 Main St","city":"Munich","state":"BY","country":"DE","postalCode":"80331","startDate":"2030-01-02T10:00:00","endDate":"2030-01-02T18:00:00","capacity":150,"price":59.99,"status":"PUBLISHED"}'`
- `DELETE /events/{eventId}`  
  Test: `curl -X DELETE "<EVENT_SERVICE_URL>/events/1"`
- `POST /events/{eventId}/publish`  
  Test: `curl -X POST "<EVENT_SERVICE_URL>/events/1/publish"`
- `GET /events/organizer/{organizerId}`  
  Test: `curl -X GET "<EVENT_SERVICE_URL>/events/organizer/1"`
- `GET /events`  
  Test: `curl -X GET "<EVENT_SERVICE_URL>/events"`
- `GET /events/search`  
  Test: `curl -X GET "<EVENT_SERVICE_URL>/events/search?query=test"`
- `GET /events/{eventId}/availability`  
  Test: `curl -X GET "<EVENT_SERVICE_URL>/events/1/availability"`
- `POST /events/{eventId}/reserve`  
  Test: `curl -X POST "<EVENT_SERVICE_URL>/events/1/reserve?quantity=2"`
- `POST /events/{eventId}/release`  
  Test: `curl -X POST "<EVENT_SERVICE_URL>/events/1/release?quantity=2"`

## reservation-service

Base path: `/reservations`

- `POST /reservations`  
  Test: `curl -X POST "<RESERVATION_SERVICE_URL>/reservations" -H "Content-Type: application/json" -d '{"userId":1,"eventId":1,"quantity":2,"idempotencyKey":"resv-123"}'`
- `GET /reservations`  
  Test: `curl -X GET "<RESERVATION_SERVICE_URL>/reservations"`
- `GET /reservations/{reservationId}`  
  Test: `curl -X GET "<RESERVATION_SERVICE_URL>/reservations/1"`
- `GET /reservations/user/{userId}`  
  Test: `curl -X GET "<RESERVATION_SERVICE_URL>/reservations/user/1"`
- `PUT /reservations/{reservationId}`  
  Test: `curl -X PUT "<RESERVATION_SERVICE_URL>/reservations/1" -H "Content-Type: application/json" -d '{"userId":1,"eventId":1,"quantity":3,"idempotencyKey":"resv-123-update"}'`
- `DELETE /reservations/{reservationId}`  
  Test: `curl -X DELETE "<RESERVATION_SERVICE_URL>/reservations/1"`
- `POST /reservations/{reservationId}/confirm`  
  Test: `curl -X POST "<RESERVATION_SERVICE_URL>/reservations/1/confirm"`
- `POST /reservations/{reservationId}/cancel`  
  Test: `curl -X POST "<RESERVATION_SERVICE_URL>/reservations/1/cancel"`
- `GET /reservations/ping`  
  Test: `curl -X GET "<RESERVATION_SERVICE_URL>/reservations/ping"`

## payment-service

Base path: `/payments`

- `POST /payments/intents`  
  Test: `curl -X POST "<PAYMENT_SERVICE_URL>/payments/intents" -H "Content-Type: application/json" -d '{"reservationId":"resv-123","userId":1,"amount":49.99,"currency":"USD","paymentMethod":"CARD","description":"Ticket purchase","idempotencyKey":"pay-123"}'`
- `POST /payments/intents/{intentId}/capture`  
  Test: `curl -X POST "<PAYMENT_SERVICE_URL>/payments/intents/1/capture"`
- `GET /payments/intents/{intentId}`  
  Test: `curl -X GET "<PAYMENT_SERVICE_URL>/payments/intents/1"`
- `GET /payments/intents/user/{userId}`  
  Test: `curl -X GET "<PAYMENT_SERVICE_URL>/payments/intents/user/1"`
- `POST /payments`  
  Test: `curl -X POST "<PAYMENT_SERVICE_URL>/payments" -H "Content-Type: application/json" -d '{"reservationId":"resv-123","userId":1,"amount":49.99,"currency":"USD","paymentMethod":"CARD","description":"Ticket purchase","idempotencyKey":"pay-legacy-123"}'`
- `GET /payments`  
  Test: `curl -X GET "<PAYMENT_SERVICE_URL>/payments"`
- `GET /payments/{paymentId}`  
  Test: `curl -X GET "<PAYMENT_SERVICE_URL>/payments/1"`
- `GET /payments/user/{userId}`  
  Test: `curl -X GET "<PAYMENT_SERVICE_URL>/payments/user/1"`
- `PUT /payments/{paymentId}/status`  
  Test: `curl -X PUT "<PAYMENT_SERVICE_URL>/payments/1/status" -H "Content-Type: application/json" -d '{"status":"COMPLETED"}'`
- `POST /payments/{paymentId}/process`  
  Test: `curl -X POST "<PAYMENT_SERVICE_URL>/payments/1/process"`
- `POST /payments/cleanup`  
  Test: `curl -X POST "<PAYMENT_SERVICE_URL>/payments/cleanup"`
- `GET /payments/ping`  
  Test: `curl -X GET "<PAYMENT_SERVICE_URL>/payments/ping"`

## user-service

Base path: `/users`

- `GET /users/ping`  
  Test: `curl -X GET "<USER_SERVICE_URL>/users/ping"`
- `GET /users`  
  Test: `curl -X GET "<USER_SERVICE_URL>/users"`
- `GET /users/me`  
  Test: `curl -X GET "<USER_SERVICE_URL>/users/me" -H "Authorization: Bearer <TOKEN>"`
- `GET /users/{id}`  
  Test: `curl -X GET "<USER_SERVICE_URL>/users/1"`
- `PUT /users/{id}`  
  Test: `curl -X PUT "<USER_SERVICE_URL>/users/1" -H "Content-Type: application/json" -d '{"email":"updated.user@example.com","firstName":"Jane","lastName":"Doe","status":"ACTIVE"}'`
- `DELETE /users/{id}`  
  Test: `curl -X DELETE "<USER_SERVICE_URL>/users/1"`

### auth (user-service)

Base path: `/auth`

- `POST /auth/register`  
  Test: `curl -X POST "<USER_SERVICE_URL>/auth/register" -H "Content-Type: application/json" -d '{"email":"user@example.com","password":"Password123","firstName":"John","lastName":"Doe"}'`
- `POST /auth/login`  
  Test: `curl -X POST "<USER_SERVICE_URL>/auth/login" -H "Content-Type: application/json" -d '{"email":"user@example.com","password":"Password123"}'`
- `GET /auth/test`  
  Test: `curl -X GET "<USER_SERVICE_URL>/auth/test"`
- `POST /auth/simple-test`  
  Test: `curl -X POST "<USER_SERVICE_URL>/auth/simple-test"`

## notification-service

No HTTP controller endpoints detected in codebase.

## api-gateway

No controller endpoints detected in codebase (likely configured via routing, not explicit controllers).