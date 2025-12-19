# 🎤 Réponses Orales - Entretien Java & DevOps

> **Instructions :** Ces réponses sont formulées pour être dites à l'oral. Lis-les à voix haute pour t'entraîner.

---

## 🔷 JAVA CORE

---

### "Parlez-moi de Java et ses caractéristiques"

*À dire :*

"Java est un langage orienté objet, fortement typé, qui fonctionne sur le principe **Write Once, Run Anywhere**. Le code est compilé en bytecode puis exécuté par la JVM, ce qui le rend portable.

Les caractéristiques principales sont :
- La **gestion automatique de la mémoire** avec le Garbage Collector
- La **robustesse** grâce au typage fort et à la gestion des exceptions
- La **sécurité** avec le sandboxing de la JVM
- Un **écosystème très riche** avec Maven, Spring, et des milliers de librairies

Dans mon projet, j'utilise Java 17 LTS avec les nouvelles fonctionnalités comme les records, les text blocks, et le pattern matching."

---

### "Quelle est la différence entre == et equals() ?"

*À dire :*

"L'opérateur `==` compare les **références mémoire** — est-ce que ces deux variables pointent vers le même objet ? 

La méthode `equals()` compare le **contenu** des objets.

Par exemple :
```
String a = new String("hello");
String b = new String("hello");

a == b      // false, deux objets différents en mémoire
a.equals(b) // true, même contenu
```

C'est pour ça qu'on doit toujours utiliser `equals()` pour comparer des Strings ou des objets, et `==` uniquement pour les primitives ou vérifier si une référence est null."

---

### "Expliquez les collections en Java"

*À dire :*

"Les collections en Java sont regroupées dans le framework `java.util`.

**Les principales interfaces :**
- **List** : collection ordonnée avec doublons autorisés. J'utilise ArrayList pour l'accès rapide par index, LinkedList pour les insertions fréquentes.
- **Set** : pas de doublons. HashSet pour la performance, TreeSet pour le tri automatique.
- **Map** : paires clé-valeur. HashMap pour la performance O(1), TreeMap pour le tri par clés.
- **Queue** : file d'attente FIFO, utile pour les traitements asynchrones.

Dans mon projet, j'utilise beaucoup les Lists pour stocker les réservations d'un utilisateur, et les Maps pour le caching temporaire."

---

### "Qu'est-ce qu'une exception et comment les gérer ?"

*À dire :*

"Une exception représente une erreur ou une situation anormale pendant l'exécution.

Il y a deux types :
- **Checked exceptions** : vérifiées à la compilation, comme IOException. On doit les traiter avec try-catch ou les propager avec throws.
- **Unchecked exceptions** : héritent de RuntimeException, comme NullPointerException. Pas obligatoire de les traiter explicitement.

Ma stratégie dans mon projet :
- Je crée des **exceptions métier** comme `ResourceNotFoundException`
- J'ai un **GlobalExceptionHandler** avec `@RestControllerAdvice` qui attrape toutes les exceptions et retourne des réponses HTTP appropriées
- J'évite les try-catch partout en laissant remonter les exceptions jusqu'au handler global

Exemple : quand une réservation n'existe pas, je lance `ResourceNotFoundException` qui est transformée en HTTP 404 automatiquement."

---

### "Comment fonctionne le multi-threading en Java ?"

*À dire :*

"Java offre plusieurs façons de faire du multi-threading :

**Niveau basique :**
- Étendre la classe `Thread` ou implémenter `Runnable`
- Utiliser `synchronized` pour protéger les sections critiques
- Les mots-clés `wait()` et `notify()` pour la communication entre threads

**Niveau moderne (ce que j'utilise) :**
- `ExecutorService` et les thread pools pour gérer efficacement les threads
- `CompletableFuture` pour les opérations asynchrones chaînées
- Les collections thread-safe comme `ConcurrentHashMap`

Dans mon projet microservices, chaque requête HTTP est traitée dans un thread séparé par Tomcat. Spring gère ça automatiquement, et mes services sont **stateless** donc pas de problème de concurrence — sauf pour la gestion de capacité où j'utilise un **verrou pessimiste** en base de données."

---

### "Qu'est-ce que les Generics ?"

*À dire :*

"Les Generics permettent d'écrire du **code réutilisable et type-safe**. Au lieu de travailler avec des Objects et faire des casts dangereux, on paramètre nos classes avec un type.

Exemple simple :
```java
List<String> names = new ArrayList<>();
names.add("Alice");
String name = names.get(0);  // Pas de cast nécessaire
```

Dans mon projet, j'utilise les Generics partout :
- Mes repositories : `JpaRepository<Event, Long>` — Event est l'entité, Long est le type de l'ID
- Mes réponses paginées : `Page<EventResponse>`
- Les Optional : `Optional<Reservation>`

Les Generics évitent les ClassCastException à l'exécution en détectant les erreurs de type dès la compilation."

---

### "Expliquez les annotations en Java"

*À dire :*

"Les annotations sont des métadonnées qu'on ajoute au code. Elles commencent par `@` et peuvent être traitées à la compilation ou à l'exécution.

**Mes principales annotations dans mon projet :**

- `@RestController` : indique que c'est un contrôleur REST
- `@Service`, `@Repository` : marquent les beans Spring
- `@Autowired` / `@RequiredArgsConstructor` : injection de dépendances
- `@Transactional` : gestion des transactions
- `@Valid` : validation des DTOs
- `@Entity`, `@Table`, `@Column` : mapping JPA

On peut aussi créer ses propres annotations. Par exemple, j'aurais pu créer `@Audited` pour logger automatiquement les appels à certaines méthodes.

Le gros avantage, c'est que ça rend le code déclaratif et lisible — je dis CE que je veux, pas COMMENT le faire."

---

## 🌿 SPRING FRAMEWORK

---

### "Pourquoi utiliser Spring Boot plutôt que Java EE ?"

*À dire :*

"Spring Boot offre plusieurs avantages majeurs :

**1. Configuration minimale**
Avec l'auto-configuration, Spring détecte mes dépendances et configure automatiquement. Si j'ajoute `spring-data-jpa`, il configure Hibernate. Si j'ajoute `spring-security`, il active la sécurité.

**2. Serveur embarqué**
Pas besoin de déployer un WAR sur Tomcat externe. Mon application est un JAR exécutable avec Tomcat intégré. Un simple `java -jar app.jar` suffit.

**3. Starters**
Au lieu de gérer 20 dépendances individuellement, un seul starter comme `spring-boot-starter-web` inclut tout ce qu'il faut.

**4. Actuator**
Health checks, métriques, et endpoints de monitoring inclus.

**5. Écosystème Spring Cloud**
Pour les microservices : Eureka, Config Server, Gateway, tout s'intègre naturellement.

Dans mon projet, démarrer un nouveau microservice prend 5 minutes au lieu de plusieurs heures avec Java EE."

---

### "Expliquez @RestController vs @Controller"

*À dire :*

"`@Controller` est l'annotation de base pour les contrôleurs Spring MVC. Il s'attend à ce que les méthodes retournent des **vues** — des noms de templates HTML à rendre.

`@RestController` combine `@Controller` + `@ResponseBody`. Ça signifie que toutes les méthodes retournent directement des **données** — JSON ou XML — pas des vues.

Dans une API REST comme la mienne, j'utilise toujours `@RestController` :
```java
@RestController
@RequestMapping("/events")
public class EventController {
    
    @GetMapping("/{id}")
    public EventResponse getEvent(@PathVariable Long id) {
        // Retourne directement du JSON, pas une vue
        return eventService.getEvent(id);
    }
}
```

Spring utilise Jackson pour sérialiser automatiquement mes objets Java en JSON."

---

### "Comment sécurisez-vous vos APIs ?"

*À dire :*

"J'utilise **Spring Security avec JWT** (JSON Web Tokens).

**Le flow :**
1. L'utilisateur s'authentifie avec email/mot de passe sur `/auth/login`
2. Je vérifie le mot de passe avec BCrypt
3. Je génère un JWT contenant l'ID utilisateur, son email, ses rôles
4. Le client stocke ce token et l'envoie dans le header `Authorization: Bearer <token>`
5. L'API Gateway valide le token avant de router vers les services

**Configuration Spring Security :**
- Session stateless — pas de session côté serveur
- CSRF désactivé — normal pour une API REST
- Les endpoints `/auth/**` et `/actuator/health` sont publics
- Tout le reste nécessite un token valide

**Avantages du JWT :**
- Stateless : pas besoin de partager une session entre les services
- L'API Gateway valide le token sans appeler le User Service à chaque requête
- Le token contient les rôles, donc l'autorisation est immédiate"

---

### "Comment gérez-vous les erreurs dans Spring ?"

*À dire :*

"J'ai une gestion centralisée avec `@RestControllerAdvice` :

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(ResourceNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ErrorResponse handleNotFound(ResourceNotFoundException ex) {
        return new ErrorResponse("NOT_FOUND", ex.getMessage());
    }
    
    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleBadRequest(IllegalArgumentException ex) {
        return new ErrorResponse("BAD_REQUEST", ex.getMessage());
    }
}
```

**Les avantages :**
- Code métier propre — je lance juste l'exception, pas de try-catch partout
- Réponses d'erreur cohérentes — même format JSON pour toutes les erreurs
- Mapping clair : exception X → code HTTP Y

Je log aussi toutes les exceptions avec le correlation ID pour le debugging en production."

---

### "Qu'est-ce que Spring Data JPA ?"

*À dire :*

"Spring Data JPA est une abstraction au-dessus de JPA/Hibernate qui génère automatiquement les requêtes.

**Je n'écris que des interfaces :**
```java
public interface EventRepository extends JpaRepository<Event, Long> {
    List<Event> findByOrganizerId(Long organizerId);
    Page<Event> findByStatusOrderByStartDateAsc(String status, Pageable pageable);
}
```

Spring parse les noms de méthodes et génère le SQL correspondant.

**Ce que j'obtiens gratuitement :**
- CRUD complet : save, findById, findAll, delete
- Pagination et tri
- Requêtes personnalisées via le nom de méthode
- Support des transactions

Pour les requêtes complexes, j'utilise `@Query` avec JPQL ou SQL natif.

Le gain de productivité est énorme — je n'écris plus de DAO avec du JDBC boilerplate."

---

## 🏗️ ARCHITECTURE & PATTERNS

---

### "Expliquez l'architecture de votre projet"

*À dire :*

"C'est une **architecture microservices** pour une plateforme de gestion d'événements.

**Les services métier :**
- **User Service** : authentification JWT, gestion des profils
- **Event Service** : CRUD événements, gestion de capacité
- **Reservation Service** : réservation de billets, validation des limites
- **Payment Service** : intentions de paiement, capture

**L'infrastructure :**
- **API Gateway** : point d'entrée unique, validation JWT, routing
- **Eureka Server** : service discovery — les services s'enregistrent et se trouvent dynamiquement
- **Config Server** : configuration centralisée pour tous les environnements

**Bases de données :**
Pattern **Database per Service** — chaque service a sa propre base PostgreSQL. Ça garantit l'indépendance et évite le couplage.

**Communication :**
REST synchrone entre services avec OpenFeign, avec des fallbacks en cas d'indisponibilité."

---

### "Qu'est-ce que le pattern Saga ?"

*À dire :*

"Le pattern Saga gère les **transactions distribuées** dans les microservices.

Dans un monolithe, une transaction ACID couvre toute l'opération. En microservices, chaque service a sa propre base — impossible d'utiliser une transaction unique.

**Mon exemple concret — création de réservation :**

Étapes normales :
1. Réserver la capacité dans Event Service
2. Créer la réservation dans Reservation Service
3. Créer l'intention de paiement dans Payment Service

Si l'étape 3 échoue, je dois **compenser** :
- Annuler la réservation
- Libérer la capacité réservée

**Dans mon code :**
```java
try {
    eventService.reserveCapacity(eventId, quantity);
    reservation = createReservation();
    paymentService.createIntent(reservation);
} catch (Exception e) {
    // Compensation
    eventService.releaseCapacity(eventId, quantity);
    reservationRepository.delete(reservation);
    throw e;
}
```

C'est de l'**orchestration** — le Reservation Service coordonne la saga. L'alternative est la **chorégraphie** avec des événements asynchrones."

---

### "Qu'est-ce que l'idempotence et pourquoi c'est important ?"

*À dire :*

"Une opération est **idempotente** si l'exécuter plusieurs fois produit le même résultat qu'une seule fois.

**Pourquoi c'est crucial :**
- Le réseau est instable — timeouts, retries automatiques
- L'utilisateur peut double-cliquer
- Les messages peuvent être dupliqués

**Mon implémentation :**
Le client envoie une clé d'idempotence unique avec chaque requête de réservation :

```java
public ReservationResponse createReservation(Request request) {
    if (request.getIdempotencyKey() != null) {
        Optional<Reservation> existing = 
            repository.findByIdempotencyKey(request.getIdempotencyKey());
        if (existing.isPresent()) {
            return mapToResponse(existing.get()); // Retourne l'existant
        }
    }
    // Créer nouvelle réservation...
}
```

Même si la requête est envoyée 3 fois avec la même clé, une seule réservation est créée. C'est transparent pour le client."

---

### "Comment gérez-vous la concurrence sur les ressources partagées ?"

*À dire :*

"Le problème classique : deux utilisateurs réservent les dernières places en même temps.

**Ma solution — Pessimistic Locking :**

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("SELECT c FROM EventCapacity c WHERE c.eventId = :eventId")
EventCapacity findByEventIdWithLock(Long eventId);
```

Quand je lis la capacité avec ce verrou, la base de données bloque les autres lectures jusqu'à la fin de ma transaction. Ça garantit qu'une seule réservation peut modifier la capacité à la fois.

**L'alternative — Optimistic Locking :**
Un champ `@Version` sur l'entité. Si deux transactions modifient simultanément, l'une échoue avec `OptimisticLockException` et doit réessayer.

J'ai choisi le pessimistic locking car les réservations sont critiques — je préfère bloquer brièvement plutôt que faire échouer des transactions légitimes."

---

## 🔧 DEVOPS

---

### "Pourquoi utiliser Docker ?"

*À dire :*

"Docker résout le problème du **'ça marche sur ma machine'**.

Un conteneur package l'application avec toutes ses dépendances — JRE, librairies, configuration. Ce qui tourne en dev tourne exactement pareil en prod.

**Mes Dockerfiles utilisent le multi-stage build :**
- Stage 1 : compile avec Maven + JDK (image ~800MB)
- Stage 2 : runtime avec JRE slim seulement (image ~150MB)

**Docker Compose pour le développement local :**
Une seule commande `docker-compose up` démarre :
- 5 bases PostgreSQL (une par service)
- Redis pour le caching
- Tout le réseau est configuré automatiquement

**Avantages que j'ai constatés :**
- Onboarding d'un nouveau développeur : 10 minutes au lieu de 2 heures
- Environnements isolés — pas de conflits de versions
- Facilite le passage à Kubernetes"

---

### "Expliquez votre pipeline CI/CD"

*À dire :*

"J'utilise GitHub Actions avec 3 stages principaux :

**Stage 1 — Test :**
- Checkout du code
- Setup Java 17
- `mvn test` — tests unitaires et d'intégration
- Rapport de couverture de code

**Stage 2 — Build :**
- Construction des images Docker pour chaque service
- Tag avec le SHA du commit pour la traçabilité
- Push vers le registry Docker

**Stage 3 — Deploy :**
- Seulement sur la branche `main`
- `kubectl apply` pour mettre à jour Kubernetes
- Rolling update pour zero-downtime

**Bonnes pratiques :**
- Les secrets sont dans GitHub Secrets, jamais dans le code
- Build matriciel — tous les services en parallèle
- Cache des dépendances Maven pour accélérer
- Le pipeline s'arrête dès qu'un test échoue"

---

### "Comment déploieriez-vous sur Kubernetes ?"

*À dire :*

"Kubernetes orchestre mes conteneurs en production.

**Les ressources principales :**

**Deployment** — gère les pods et le scaling
```yaml
replicas: 3  # Haute disponibilité
livenessProbe: /actuator/health/liveness
readinessProbe: /actuator/health/readiness
```

**Service** — load balancing interne entre les pods

**Ingress** — expose l'API Gateway vers l'extérieur avec TLS

**HorizontalPodAutoscaler** — scaling automatique basé sur CPU/mémoire

**ConfigMaps et Secrets** — configuration et credentials injectés

**Ce que Kubernetes m'apporte :**
- **Self-healing** : un pod crash → il redémarre automatiquement
- **Rolling updates** : déploiement sans interruption
- **Service discovery** : les services se trouvent par nom DNS
- **Scaling horizontal** : ajouter des instances en une commande"

---

### "Comment surveillez-vous vos applications en production ?"

*À dire :*

"Je suis les **trois piliers de l'observabilité** :

**1. Logs**
- Format JSON structuré pour l'indexation
- Correlation ID pour tracer une requête à travers tous les services
- Niveaux appropriés : DEBUG en dev, INFO en prod

**2. Métriques**
- Spring Boot Actuator expose `/actuator/prometheus`
- Métriques HTTP : latence, codes de réponse, throughput
- Métriques JVM : mémoire, threads, GC
- Métriques custom : réservations créées, paiements capturés

**3. Tracing distribué**
- Pour suivre une requête de l'API Gateway jusqu'au Payment Service
- Spring Cloud Sleuth ou OpenTelemetry

**Stack typique :**
Prometheus pour collecter, Grafana pour visualiser, AlertManager pour les alertes.

**Mes alertes critiques :**
- Taux d'erreur > 5%
- Latence P99 > 2 secondes
- Pods qui redémarrent fréquemment"

---

### "Comment gérez-vous les secrets ?"

*À dire :*

"Les secrets ne sont **jamais** dans le code source.

**En développement :**
- Variables d'environnement locales
- Fichier `.env` ignoré par Git

**En CI/CD :**
- GitHub Secrets pour les credentials Docker, les clés API
- Injectés comme variables d'environnement dans le workflow

**En production Kubernetes :**
- Kubernetes Secrets, montés comme variables d'environnement ou fichiers
- Optionnellement chiffrés avec Sealed Secrets ou intégrés à HashiCorp Vault

**Dans mon code Spring :**
```java
@Value("${jwt.secret}")
private String jwtSecret;  // Vient de la variable d'environnement JWT_SECRET
```

Le même code fonctionne partout — seule la source du secret change selon l'environnement."

---

## ❓ QUESTIONS COMPORTEMENTALES

---

### "Parlez-moi d'un problème technique difficile que vous avez résolu"

*À dire :*

"Dans mon projet, j'ai eu un problème de **race condition** sur la gestion de capacité.

**Le problème :**
Deux utilisateurs réservaient les dernières places simultanément. Les deux requêtes lisaient 2 places disponibles, réservaient 2 chacune, et on se retrouvait avec -2 places.

**Ma démarche :**
1. J'ai reproduit le bug avec deux threads concurrents en test
2. J'ai analysé le flow — la lecture et l'écriture n'étaient pas atomiques
3. J'ai implémenté un **pessimistic lock** sur la lecture de capacité

**La solution :**
```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
EventCapacity findByEventIdWithLock(Long eventId);
```

**Résultat :**
Le problème était résolu, et j'ai ajouté un test de concurrence pour éviter les régressions."

---

### "Comment restez-vous à jour techniquement ?"

*À dire :*

"J'utilise plusieurs sources :

**Pour Java/Spring :**
- La documentation officielle Spring — très bien maintenue
- Le blog de Baeldung pour les tutoriels pratiques
- Les release notes de chaque nouvelle version

**Pour l'architecture :**
- Les talks de conférences (Devoxx, SpringOne)
- Les blogs de Netflix, Uber, qui partagent leurs solutions à grande échelle

**Pour DevOps :**
- La documentation Kubernetes
- Les blogs de cloud providers (AWS, GCP)

**En pratique :**
- Je fais des projets personnels pour expérimenter les nouvelles technos
- Ce projet Event Platform m'a permis de pratiquer Spring Boot 3, Kubernetes, et les microservices"

---

## 💡 Questions à poser à l'Entreprise

1. "Quelle est votre stack technique actuelle et avez-vous des migrations prévues ?"
2. "Comment sont organisées les équipes — par service, par feature ?"
3. "Quel est votre processus de code review ?"
4. "Utilisez-vous des event-driven architectures ?"
5. "Quels sont les principaux défis techniques actuels ?"
