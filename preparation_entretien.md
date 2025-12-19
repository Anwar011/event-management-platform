# 🎯 Préparation Entretien Technique - Java (70%) + DevOps (30%)

## 📋 Présentation du Projet

**Nom**: Event Management Platform  
**Stack**: Java 17, Spring Boot 3.2, Spring Cloud 2023, PostgreSQL 15, Redis 7, Docker  
**Architecture**: Microservices cloud-native

---

## 💬 Discours de Présentation (Oral)

> **Version courte (2 min):**
>
> "J'ai développé une plateforme de gestion d'événements basée sur une architecture microservices. Le projet utilise **Java 17 avec Spring Boot 3.2** et comprend 5 services métier : un service utilisateur avec authentification JWT, un service événements pour le CRUD et la gestion de capacité, un service réservation avec gestion d'idempotence, un service paiement avec le pattern intent/capture, et un service notifications.
>
> Pour l'infrastructure, j'ai utilisé **Spring Cloud** avec Eureka pour le service discovery, Config Server pour la configuration centralisée, et Spring Cloud Gateway comme API Gateway avec validation JWT et rate limiting.
>
> Côté base de données, j'ai appliqué le pattern **Database per Service** avec PostgreSQL et Flyway pour les migrations. J'utilise Docker Compose en développement et le projet est conçu pour Kubernetes en production.
>
> Ce qui me plaît dans ce projet, c'est la gestion des patterns de résilience comme le pattern Saga pour les transactions distribuées, l'idempotence sur les réservations, et l'optimistic locking sur la gestion de capacité."

---

## 🔷 PARTIE JAVA (70%)

### 1. Spring Boot & Spring Framework

**Q: Expliquez la différence entre Spring et Spring Boot?**
```
R: Spring est un framework modulaire offrant IoC/DI et diverses fonctionnalités.
   Spring Boot est une surcouche qui simplifie la configuration avec:
   - Auto-configuration (détection automatique des dépendances)
   - Starters (groupes de dépendances préconfigurés)
   - Serveur embarqué (Tomcat/Jetty)
   - Actuator (monitoring/health checks)
   
   Dans mon projet, j'utilise spring-boot-starter-web, spring-boot-starter-data-jpa,
   et spring-boot-starter-security.
```

**Q: Comment fonctionne l'injection de dépendances dans votre projet?**
```
R: J'utilise l'injection par constructeur avec @RequiredArgsConstructor de Lombok:

   @Service
   @RequiredArgsConstructor
   public class EventService {
       private final EventRepository eventRepository; // Injecté via constructeur
   }
   
   Avantages: 
   - Immutabilité (final), 
   - Facilite les tests unitaires
   - Détection des dépendances circulaires au démarrage
```

**Q: Que fait l'annotation @Transactional et comment l'utilisez-vous?**
```
R: @Transactional gère les transactions de façon déclarative:
   
   - @Transactional sur la classe: toutes les méthodes sont transactionnelles
   - @Transactional(readOnly = true): optimise les lectures (pas de dirty checking)
   - Rollback automatique sur RuntimeException
   
   Dans mon EventService:
   @Transactional
   public boolean reserveCapacity(Long eventId, int quantity) {
       // Utilise un verrou pessimiste pour éviter les conditions de course
       EventCapacity capacity = eventCapacityRepository.findByEventIdWithLock(eventId);
       ...
   }
```

---

### 2. Architecture Microservices

**Q: Pourquoi avoir choisi une architecture microservices?**
```
R: Plusieurs raisons business et techniques:

   1. Scalabilité indépendante: le service Reservation peut scaler séparément
   2. Déploiement indépendant: mettre à jour Payment sans redéployer tout
   3. Isolation des pannes: si Notification tombe, les réservations fonctionnent
   4. Équipes autonomes: chaque équipe gère son domaine
   5. Technologie adaptée: possibilité de choisir la stack par service

   Trade-offs acceptés:
   - Complexité opérationnelle accrue
   - Transactions distribuées (pattern Saga)
   - Communication réseau (latence)
```

**Q: Comment gérez-vous la communication inter-services?**
```
R: Communication synchrone REST via Feign/OpenFeign:

   @FeignClient(name = "event-service")
   public interface EventServiceClient {
       @GetMapping("/events/{eventId}/availability")
       EventAvailabilityResponse getEventAvailability(@PathVariable Long eventId);
   }
   
   Avec fallback en cas d'indisponibilité du service:
   - Valeurs par défaut
   - Optional<EventServiceClient> pour injection conditionnelle
```

**Q: Comment gérez-vous les transactions distribuées?**
```
R: J'utilise le pattern SAGA avec compensation:

   Réservation Flow:
   1. Réserver capacité dans Event Service
   2. Créer réservation dans Reservation Service
   3. Créer payment intent dans Payment Service
   
   Si étape 3 échoue:
   - Annuler réservation (compensation)
   - Libérer capacité (releaseCapacity)
   
   Implémenté dans mon ReservationService avec try/catch et compensation explicite.
```

---

### 3. Service Discovery & Configuration

**Q: Comment fonctionne Eureka dans votre architecture?**
```
R: Eureka est le service registry Netflix:

   1. Les services s'enregistrent au démarrage avec leur IP/port
   2. Eureka maintient un registre des instances disponibles
   3. Les clients interrogent Eureka pour découvrir les services
   4. Health checks réguliers pour retirer les instances mortes
   
   Configuration dans application.yml:
   eureka:
     client:
       serviceUrl:
         defaultZone: http://localhost:8761/eureka/
```

**Q: Quel est le rôle du Config Server?**
```
R: Spring Cloud Config Server centralise la configuration:

   Avantages:
   - Une seule source de vérité
   - Configuration par environnement (dev, prod)
   - Refresh runtime sans redéploiement
   - Encryption des secrets
   
   Dans mon projet: mode "native" (fichiers locaux), mais extensible vers Git.
```

---

### 4. Sécurité & JWT

**Q: Comment fonctionne l'authentification JWT dans votre projet?**
```
R: Flow complet:

   1. Login: POST /auth/login (email + password)
   2. Validation BCrypt du mot de passe
   3. Génération JWT signé (HS512):
   
   return Jwts.builder()
       .subject(userId.toString())
       .claim("email", email)
       .claim("roles", roles)
       .expiration(expiryDate)
       .signWith(key)
       .compact();
   
   4. Le token est retourné au client
   5. Chaque requête inclut: Authorization: Bearer <token>
   6. L'API Gateway valide le token avant de router
```

**Q: Comment sécurisez-vous les endpoints sensibles?**
```
R: Configuration Spring Security dans chaque service:

   @Bean
   public SecurityFilterChain filterChain(HttpSecurity http) {
       return http
           .csrf(csrf -> csrf.disable())  // API REST stateless
           .sessionManagement(session -> 
               session.sessionCreationPolicy(STATELESS))
           .authorizeHttpRequests(auth -> auth
               .requestMatchers("/auth/**", "/actuator/**").permitAll()
               .anyRequest().authenticated()
           )
           .build();
   }
```

---

### 5. Persistence & JPA

**Q: Pourquoi Database-per-Service et pas une base partagée?**
```
R: Raisons:
   
   1. Couplage faible: chaque service peut évoluer son schéma
   2. Technologie adaptée: PostgreSQL pour User, pourrait être MongoDB pour logs
   3. Scalabilité: sharding/réplication indépendante
   4. Isolation: problème de performance isolé au service
   
   Dans mon projet: 5 bases PostgreSQL (userdb, eventdb, reservationdb, paymentdb, notificationdb)
```

**Q: Comment gérez-vous la concurrence sur la capacité des événements?**
```
R: Pessimistic locking avec JPA:

   @Lock(LockModeType.PESSIMISTIC_WRITE)
   @Query("SELECT c FROM EventCapacity c WHERE c.eventId = :eventId")
   EventCapacity findByEventIdWithLock(@Param("eventId") Long eventId);
   
   Cela évite les conditions de course lors de réservations simultanées.
   Alternative: Optimistic locking avec @Version
```

**Q: Comment utilisez-vous Flyway?**
```
R: Migration de schéma versionnée:

   src/main/resources/db/migration/
   ├── V1__create_users_table.sql
   ├── V2__add_roles_column.sql
   └── V3__create_events_table.sql
   
   Flyway maintient une table flyway_schema_history pour tracker les migrations.
   Rollback possible avec scripts U1__, U2__...
```

---

### 6. Patterns & Bonnes Pratiques

**Q: Expliquez le pattern Idempotency dans votre service de réservation?**
```
R: Garantit qu'une requête répétée produit le même résultat:

   if (request.getIdempotencyKey() != null) {
       Optional<Reservation> existing = repository.findByIdempotencyKey(key);
       if (existing.isPresent()) {
           return mapToResponse(existing.get()); // Retourne l'existant
       }
   }
   
   Cas d'usage: timeout réseau, retry automatique, double-clic utilisateur
   La clé idempotency est unique (UUID généré côté client)
```

**Q: Comment gérez-vous les erreurs dans vos APIs?**
```
R: Global Exception Handler avec @RestControllerAdvice:

   @ExceptionHandler(ResourceNotFoundException.class)
   public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
       return ResponseEntity.status(NOT_FOUND)
           .body(new ErrorResponse("NOT_FOUND", ex.getMessage()));
   }
   
   Codes HTTP appropriés: 400 validation, 404 not found, 409 conflict, 500 server error
```

---

## 🔧 PARTIE DEVOPS (30%)

### 1. Docker & Containers

**Q: Expliquez votre docker-compose.yml?**
```
R: Orchestration de l'infrastructure locale:

   services:
     - postgres-user (port 5432): Base User Service
     - postgres-event (port 5433): Base Event Service
     - postgres-reservation (port 5434): Base Reservation Service
     - postgres-payment (port 5435): Base Payment Service
     - redis (port 6379): Cache et rate limiting
   
   Volumes persistants pour les données
   Healthchecks pour dépendances ordonnées
   Network bridge pour communication inter-containers
```

**Q: Comment construisez-vous vos images Docker?**
```
R: Multi-stage build pour optimisation:

   # Stage 1: Build
   FROM maven:3.9.4-openjdk-17 AS build
   COPY . .
   RUN mvn clean package -DskipTests
   
   # Stage 2: Runtime
   FROM openjdk:17-jre-slim
   COPY --from=build target/*.jar app.jar
   EXPOSE 8080
   ENTRYPOINT ["java", "-jar", "app.jar"]
   
   Avantages: image finale ~150MB vs ~500MB avec JDK
```

---

### 2. CI/CD & GitHub Actions

**Q: Décrivez votre pipeline CI/CD?**
```
R: GitHub Actions avec stages:

   1. Build & Test:
      - Checkout code
      - Setup Java 17
      - mvn test (unit + integration)
      - Code coverage report
   
   2. Build Docker:
      - docker build pour chaque service
      - docker push vers registry
   
   3. Deploy:
      - kubectl apply pour Kubernetes
      - ou docker-compose up pour dev
```

**Q: Comment gérez-vous les secrets dans CI/CD?**
```
R: GitHub Secrets:
   - DOCKER_USERNAME, DOCKER_PASSWORD
   - JWT_SECRET
   - DATABASE_PASSWORDS
   
   Injectés comme variables d'environnement dans les workflows.
   Jamais commités dans le code.
```

---

### 3. Kubernetes

**Q: Comment déploieriez-vous ce projet sur Kubernetes?**
```
R: Ressources Kubernetes nécessaires:

   1. Deployments: un par microservice (replicas: 2-3)
   2. Services: ClusterIP pour communication interne
   3. Ingress: exposer l'API Gateway uniquement
   4. ConfigMaps: configuration non-sensible
   5. Secrets: credentials, JWT secret
   6. PersistentVolumeClaims: pour PostgreSQL

   Stratégie de déploiement: Rolling Update (zero downtime)
```

**Q: Comment gérez-vous le scaling?**
```
R: Horizontal Pod Autoscaler (HPA):

   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   spec:
     scaleTargetRef:
       name: reservation-service
     minReplicas: 2
     maxReplicas: 10
     metrics:
     - type: Resource
       resource:
         name: cpu
         targetAverageUtilization: 80
```

---

### 4. Monitoring & Observability

**Q: Comment surveillez-vous vos microservices?**
```
R: Stack d'observabilité:

   1. Logs: SLF4J + Logback (format JSON)
      - Correlation IDs pour tracer les requêtes
   
   2. Metrics: Spring Boot Actuator + Micrometer
      - /actuator/health
      - /actuator/prometheus
   
   3. Tracing: (prévu) Spring Cloud Sleuth/Zipkin
   
   4. Dashboards: Grafana + Prometheus
```

**Q: Expliquez les endpoints Actuator que vous utilisez?**
```
R: 
   /actuator/health: état du service et dépendances
   /actuator/info: métadonnées (version, git commit)
   /actuator/metrics: métriques JVM, HTTP, custom
   /actuator/prometheus: format Prometheus pour scraping
   
   Sécurisés en production avec Spring Security.
```

---

## ⚡ Questions Techniques Avancées

**Q: Comment gérez-vous un pic de charge soudain?**
```
R: Plusieurs mécanismes:

   1. Rate Limiting sur API Gateway (Redis-based)
   2. HPA Kubernetes pour auto-scaling
   3. Connection pooling (HikariCP)
   4. Optimistic retries avec backoff exponentiel
   5. Circuit breaker (Resilience4j prévu)
```

**Q: Que se passe-t-il si le service Event est down pendant une réservation?**
```
R: Pattern de résilience implémenté:

   private EventServiceClient.EventResponse getEventSafely(Long eventId) {
       try {
           return eventServiceClient.getEvent(eventId);
       } catch (Exception e) {
           log.error("Event Service unavailable, using fallback");
           return new EventResponse(eventId, "Default", "PUBLISHED", 100, 29.99);
       }
   }
   
   + Optional<EventServiceClient> pour injection conditionnelle
   + Feature flag pour désactiver l'intégration
```

---

## 🎤 Points Forts à Mettre en Avant

1. **Architecture robuste**: Microservices avec patterns éprouvés (SAGA, Idempotency)
2. **Technologies modernes**: Java 17, Spring Boot 3.2, Spring Cloud 2023
3. **Sécurité**: JWT stateless, BCrypt, CORS configuré
4. **Infrastructure as Code**: Docker Compose, prêt pour Kubernetes
5. **Qualité**: Tests unitaires, migrations Flyway, logging structuré

---

## 📝 Questions à Poser à l'Entreprise

1. "Quelle est votre stratégie de déploiement (Kubernetes, ECS, VMs)?"
2. "Utilisez-vous des event-driven architectures (Kafka, RabbitMQ)?"
3. "Quels sont vos outils de monitoring (Datadog, New Relic, ELK)?"
4. "Comment gérez-vous les migrations de schéma en production?"
5. "Quelle est la stack Java/Spring utilisée?"
