# 🎯 Description Complète du Projet - Event Management Platform

## À utiliser pour l'entretien oral

---

# PARTIE 1 : PRÉSENTATION GÉNÉRALE

---

## "Présentez votre projet"

> "J'ai conçu et développé une **plateforme de gestion d'événements complète** basée sur une architecture **microservices cloud-native**. 
>
> L'objectif métier est de permettre à des **organisateurs** de créer et publier des événements — que ce soit des concerts, des conférences tech, des spectacles ou des salons — et aux **utilisateurs** de découvrir ces événements, réserver des places, et payer en ligne de manière sécurisée.
>
> C'est un projet complet qui couvre tout le cycle de vie : de l'inscription utilisateur jusqu'à la confirmation de paiement, en passant par la recherche d'événements et la gestion de capacité en temps réel."

---

# PARTIE 2 : STACK TECHNIQUE DÉTAILLÉE

---

## "Quelle stack technique avez-vous utilisée ?"

> "Pour le backend, j'utilise **Java 17 LTS** avec **Spring Boot 3.2** — la dernière version majeure. J'ai choisi Java 17 pour les nouvelles fonctionnalités comme les **records** pour mes DTOs, les **text blocks** pour les requêtes SQL, et les améliorations de performance de la JVM.
>
> Pour l'écosystème microservices, j'utilise **Spring Cloud 2023.0.0** qui inclut :
> - **Spring Cloud Netflix Eureka** pour le service discovery
> - **Spring Cloud Config** pour la configuration centralisée
> - **Spring Cloud Gateway** comme API Gateway réactive
> - **Spring Cloud OpenFeign** pour les appels HTTP déclaratifs entre services
>
> Pour la persistance :
> - **Spring Data JPA** avec **Hibernate** comme ORM
> - **PostgreSQL 15** comme base de données relationnelle — une instance par service
> - **Flyway** pour les migrations de schéma versionnées
> - **HikariCP** pour le connection pooling — c'est le pool par défaut de Spring Boot, très performant
>
> Pour le caching et rate limiting :
> - **Redis 7** en mode Alpine pour la légèreté
>
> Pour la sécurité :
> - **Spring Security 6** pour l'authentification et l'autorisation
> - **JWT (JSON Web Tokens)** avec l'algorithme **HS512** pour les tokens signés
> - **BCrypt** pour le hashing des mots de passe
>
> Pour les outils de développement :
> - **Maven** en multi-module pour le build
> - **Lombok** pour réduire le boilerplate (getters, setters, builders)
> - **JUnit 5** et **Mockito** pour les tests
> - **Docker** et **Docker Compose** pour la containerisation
>
> Pour l'observabilité :
> - **Spring Boot Actuator** pour les health checks et métriques
> - **SLF4J avec Logback** pour le logging structuré
> - **Micrometer** pour l'exposition des métriques au format Prometheus"

---

# PARTIE 3 : ARCHITECTURE DÉTAILLÉE

---

## "Décrivez l'architecture de votre projet"

> "L'architecture suit le pattern **microservices** avec une séparation claire des responsabilités. J'ai 5 services métier et 3 composants d'infrastructure."

---

### USER SERVICE (Port 8081)

> "Le **User Service** gère tout ce qui concerne l'identité des utilisateurs.
>
> **Fonctionnalités :**
> - Inscription avec validation d'email unique
> - Authentification et génération de tokens JWT
> - Gestion des profils utilisateurs
> - Système de rôles (USER, ORGANIZER, ADMIN)
>
> **Détails techniques :**
> - Les mots de passe sont hashés avec **BCrypt** — jamais stockés en clair
> - Le JWT contient l'ID utilisateur, l'email, et les rôles dans les claims
> - Expiration configurable du token (24h par défaut)
> - Le secret JWT est externalisé dans la configuration, pas dans le code
>
> **Endpoints principaux :**
> - `POST /auth/register` — inscription
> - `POST /auth/login` — authentification, retourne le JWT
> - `GET /users/me` — profil de l'utilisateur connecté
> - `GET /users/{id}` — profil public d'un utilisateur"

---

### EVENT SERVICE (Port 8082)

> "Le **Event Service** est responsable de la gestion des événements.
>
> **Fonctionnalités :**
> - CRUD complet sur les événements
> - Workflow de publication (DRAFT → PUBLISHED → CANCELLED/COMPLETED)
> - Gestion de la capacité avec tracking temps réel
> - Recherche avec filtres (ville, type, date, mot-clé)
> - Pagination des résultats
>
> **Détails techniques :**
> - Chaque événement a une entité **EventCapacity** séparée pour tracker les places réservées
> - La capacité disponible est calculée : `total - réservée`
> - J'utilise un **verrou pessimiste** (`@Lock(PESSIMISTIC_WRITE)`) pour les opérations de réservation/libération
> - Validation métier : la date de début doit être dans le futur, le prix doit être positif
>
> **Endpoints principaux :**
> - `POST /events` — créer un événement (statut DRAFT)
> - `GET /events` — rechercher avec filtres et pagination
> - `GET /events/{id}` — détails d'un événement
> - `POST /events/{id}/publish` — publier l'événement
> - `GET /events/{id}/availability` — places disponibles
> - `POST /events/{id}/reserve` — réserver N places (appelé par Reservation Service)
> - `POST /events/{id}/release` — libérer N places (compensation)"

---

### RESERVATION SERVICE (Port 8083)

> "Le **Reservation Service** est le cœur du système — c'est là où la logique métier est la plus complexe.
>
> **Fonctionnalités :**
> - Création de réservations avec validation multi-niveaux
> - Confirmation et annulation
> - Limite de billets par utilisateur par événement (configurable, défaut 4)
> - Idempotence via clé unique
> - Génération d'identifiants de réservation lisibles (RES-XXXXXXXX)
>
> **Contraintes métier implémentées :**
> 1. L'événement doit être PUBLISHED ou DRAFT (pour les tests)
> 2. La capacité disponible doit être suffisante
> 3. L'utilisateur ne doit pas dépasser sa limite de billets
> 4. Une clé d'idempotence identique retourne la réservation existante
>
> **Pattern Saga implémenté :**
> ```
> 1. Vérifier disponibilité → Event Service
> 2. Réserver la capacité → Event Service  
> 3. Créer la réservation localement
> 4. (Si échec) Libérer la capacité → Event Service (compensation)
> ```
>
> **Communication avec Event Service :**
> - Via **OpenFeign** client déclaratif
> - Injection conditionnelle avec `Optional<EventServiceClient>`
> - Fallbacks avec valeurs par défaut si Event Service indisponible
> - Feature flag pour désactiver l'intégration en test
>
> **Endpoints principaux :**
> - `POST /reservations` — créer une réservation
> - `GET /reservations/{id}` — détails
> - `POST /reservations/{id}/confirm` — confirmer après paiement
> - `POST /reservations/{id}/cancel` — annuler et libérer les places
> - `GET /reservations/user/{userId}` — réservations d'un utilisateur"

---

### PAYMENT SERVICE (Port 8084)

> "Le **Payment Service** gère les transactions financières.
>
> **Pattern Intent/Capture :**
> C'est le pattern utilisé par Stripe et tous les processeurs de paiement modernes :
> 1. **Intent** : on crée une intention de paiement avec le montant — l'argent n'est pas encore prélevé
> 2. **Capture** : une fois le client prêt, on capture réellement le paiement
>
> Ce pattern permet d'autoriser le montant, de le garder en attente, puis de capturer ou annuler.
>
> **Entités :**
> - **PaymentIntent** : intention de paiement liée à une réservation
> - **PaymentTransaction** : trace de chaque opération (capture, refund)
>
> **Statuts du paiement :**
> - PENDING → SUCCEEDED / FAILED / CANCELLED
>
> **Endpoints principaux :**
> - `POST /payments/intents` — créer une intention
> - `GET /payments/{id}` — statut du paiement
> - `POST /payments/{id}/capture` — capturer le paiement
> - `GET /payments/reservation/{reservationId}` — paiement d'une réservation"

---

### NOTIFICATION SERVICE (Port 8085)

> "Le **Notification Service** gère l'envoi de notifications.
>
> **Types de notifications :**
> - Email de confirmation de réservation
> - Email de confirmation de paiement
> - (Prévu) SMS et notifications push
>
> **Architecture prévue :**
> - Communication **asynchrone** via message broker (RabbitMQ ou Kafka)
> - Templates d'emails avec variables dynamiques
> - Retry automatique en cas d'échec d'envoi
> - Tracking de délivrance"

---

### INFRASTRUCTURE : API GATEWAY (Port 8080)

> "L'**API Gateway** est le point d'entrée unique pour tous les clients.
>
> **Responsabilités :**
> - **Routing** : dirige `/users/**` vers User Service, `/events/**` vers Event Service, etc.
> - **Authentification** : valide le JWT avant de router
> - **Rate Limiting** : limite le nombre de requêtes par IP (avec Redis)
> - **CORS** : configuration pour les clients web
> - **Load Balancing** : répartit entre les instances via Eureka
>
> **Implémentation :**
> - Basé sur **Spring Cloud Gateway** (réactif, non-blocking)
> - Filtre JWT personnalisé qui extrait les claims et les propage aux services
> - Endpoints publics configurés : `/auth/**`, `/actuator/health`"

---

### INFRASTRUCTURE : EUREKA SERVER (Port 8761)

> "**Eureka** est le service registry — le registre central de tous les services.
>
> **Fonctionnement :**
> 1. Chaque service s'enregistre au démarrage avec son nom et son URL
> 2. Eureka maintient la liste des instances disponibles
> 3. Les clients (Feign, Gateway) interrogent Eureka pour trouver les services
> 4. Health checks réguliers — les instances mortes sont retirées
>
> **Avantages :**
> - Pas besoin de hardcoder les URLs des services
> - Load balancing automatique entre instances
> - Résilience : si une instance tombe, le trafic va vers les autres"

---

### INFRASTRUCTURE : CONFIG SERVER (Port 8888)

> "**Config Server** centralise la configuration de tous les services.
>
> **Fonctionnement :**
> - Mode **native** : fichiers de configuration locaux
> - Extensible vers **Git** pour versioning des configs
> - Profils par environnement : `application-dev.yml`, `application-prod.yml`
>
> **Avantages :**
> - Modifier une config sans redéployer
> - Refresh dynamique possible avec `@RefreshScope`
> - Les secrets peuvent être chiffrés"

---

# PARTIE 4 : BASE DE DONNÉES

---

## "Comment gérez-vous la persistance ?"

> "J'applique le pattern **Database per Service** — chaque microservice a sa propre base PostgreSQL.
>
> **Bases de données :**
> | Service | Base | Port |
> |---------|------|------|
> | User Service | userdb | 5432 |
> | Event Service | eventdb | 5433 |
> | Reservation Service | reservationdb | 5434 |
> | Payment Service | paymentdb | 5435 |
> | Notification Service | notificationdb | 5436 |
>
> **Pourquoi ce pattern ?**
> - **Indépendance** : chaque équipe gère son schéma
> - **Scalabilité** : je peux sharding une base sans impacter les autres
> - **Technologie adaptée** : je pourrais utiliser MongoDB pour les logs
> - **Isolation des pannes** : un problème de base n'affecte qu'un service
>
> **Migrations avec Flyway :**
> - Scripts versionnés : `V1__create_tables.sql`, `V2__add_indexes.sql`
> - Exécution automatique au démarrage
> - Historique dans la table `flyway_schema_history`
>
> **Modèle de données principal :**
>
> **Users Table :**
> ```sql
> id, email (unique), password_hash, first_name, last_name, role, status, created_at
> ```
>
> **Events Table :**
> ```sql
> id, title, description, event_type, venue, city, start_date, end_date, 
> capacity, price, organizer_id, status, created_at, updated_at
> ```
>
> **Reservations Table :**
> ```sql
> id, reservation_id (unique), user_id, event_id, quantity, total_price, 
> status, idempotency_key (unique), created_at, updated_at
> ```"

---

# PARTIE 5 : SÉCURITÉ

---

## "Comment sécurisez-vous l'application ?"

> "La sécurité est implémentée à plusieurs niveaux :
>
> **Authentification JWT :**
> - Token signé avec algorithme **HS512**
> - Contient : userId, email, roles, expiration
> - Stateless — pas de session côté serveur
> - Transmis via header `Authorization: Bearer <token>`
>
> **Protection des mots de passe :**
> - Hashage **BCrypt** avec salt automatique
> - Jamais stockés ou loggés en clair
>
> **API Gateway comme garde :**
> - Valide le JWT avant de router
> - Rejette les requêtes sans token valide (sauf endpoints publics)
> - Propage les informations utilisateur aux services downstream
>
> **Configuration Spring Security :**
> - Session **stateless**
> - CSRF désactivé (API REST)
> - CORS configuré pour les clients web autorisés
>
> **Gestion des secrets :**
> - Variables d'environnement pour les credentials
> - Jamais dans le code source
> - Kubernetes Secrets en production"

---

# PARTIE 6 : DEVOPS & DÉPLOIEMENT

---

## "Comment déployez-vous l'application ?"

> "**Conteneurisation Docker :**
>
> Chaque service a un Dockerfile **multi-stage** :
> - Stage build : Maven + JDK pour compiler
> - Stage runtime : JRE slim pour exécuter
> - Image finale : ~150MB au lieu de ~800MB
>
> **Docker Compose pour le développement :**
> - Une commande `docker-compose up` démarre toute l'infrastructure
> - 5 conteneurs PostgreSQL + Redis
> - Volumes persistants pour les données
> - Health checks pour l'ordre de démarrage
>
> **Préparation Kubernetes :**
> Le projet est conçu pour K8s :
> - Probes liveness/readiness via Actuator
> - Configuration via ConfigMaps et Secrets
> - Horizontal Pod Autoscaler basé sur CPU
> - Rolling updates pour zero-downtime
>
> **Pipeline CI/CD GitHub Actions :**
> 1. Tests automatiques à chaque push
> 2. Build des images Docker
> 3. Push vers le registry
> 4. Déploiement (sur main uniquement)"

---

# PARTIE 7 : CE QUE J'AI APPRIS

---

## "Qu'avez-vous appris avec ce projet ?"

> "Ce projet m'a permis de confronter la théorie des microservices à la pratique :
>
> **Défis techniques résolus :**
> - Transactions distribuées avec le pattern Saga et compensation
> - Concurrence avec le pessimistic locking
> - Résilience avec les fallbacks et feature flags
> - Idempotence pour gérer les retries réseau
>
> **Compétences acquises :**
> - Architecture microservices de bout en bout
> - Spring Cloud ecosystem complet
> - Containerisation et orchestration
> - Debugging distribué avec correlation IDs
>
> **Recul :**
> Les microservices apportent de la complexité. Pour une petite équipe, un monolithe bien structuré serait peut-être plus approprié. Mais pour une application qui doit scaler et être maintenue par plusieurs équipes, c'est le bon choix."

---

# AIDE-MÉMOIRE RAPIDE

```
STACK:        Java 17 • Spring Boot 3.2 • Spring Cloud 2023 • PostgreSQL • Redis • Docker

SERVICES:     User (8081) • Event (8082) • Reservation (8083) • Payment (8084) • Notification (8085)

INFRA:        API Gateway (8080) • Eureka (8761) • Config Server (8888)

PATTERNS:     Database per Service • Saga • Idempotence • Pessimistic Locking • JWT Auth

DEVOPS:       Docker multi-stage • Docker Compose • Kubernetes ready • GitHub Actions CI/CD
```
