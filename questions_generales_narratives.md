# 📚 Questions Générales Java & DevOps - Réponses Narratives

> Ce document contient des réponses détaillées et narratives, idéales pour un entretien oral.
> Chaque réponse est structurée pour être racontée naturellement.

---

## 🔷 JAVA FONDAMENTAL

---

### Q1: Qu'est-ce que la JVM et comment fonctionne-t-elle?

**Réponse narrative:**

"La JVM, ou Java Virtual Machine, c'est ce qui rend Java vraiment unique et portable. Quand j'écris du code Java, le compilateur `javac` ne le transforme pas directement en code machine comme en C ou C++. À la place, il génère du **bytecode** — un format intermédiaire stocké dans les fichiers `.class`.

Ce bytecode est ensuite exécuté par la JVM, qui agit comme un interpréteur entre mon code et le système d'exploitation. C'est ce qui permet le fameux principe **Write Once, Run Anywhere** : le même fichier `.jar` peut tourner sur Windows, Linux ou Mac sans recompilation.

**Exemple concret:** Dans mon projet Event Management Platform, je compile mes services avec Maven (`mvn package`), ce qui génère un fichier `event-service-1.0.0.jar`. Ce même JAR peut tourner sur ma machine de développement Ubuntu, dans un conteneur Docker Alpine, ou sur un serveur Windows en production.

La JVM fait aussi beaucoup plus que simplement exécuter le bytecode. Elle gère la **mémoire automatiquement** avec le Garbage Collector, elle optimise le code à la volée avec le **JIT Compiler** (Just-In-Time), et elle fournit des garanties de **sécurité** avec son système de classloaders et son sandboxing."

---

### Q2: Expliquez la différence entre une classe abstraite et une interface?

**Réponse narrative:**

"C'est une question classique mais importante. Pour bien comprendre, je vais prendre un exemple concret de mon projet.

Une **classe abstraite**, c'est comme un template partiel. Elle peut contenir du code commun, des attributs avec état, et des méthodes abstraites que les classes enfants doivent implémenter. On utilise l'héritage simple — une classe ne peut étendre qu'une seule classe abstraite.

**Exemple avec classe abstraite:**
```java
public abstract class BaseEntity {
    protected Long id;
    protected LocalDateTime createdAt;
    protected LocalDateTime updatedAt;
    
    // Méthode concrète partagée
    public void updateTimestamp() {
        this.updatedAt = LocalDateTime.now();
    }
    
    // Méthode abstraite - chaque entité définit sa validation
    public abstract boolean isValid();
}
```

Une **interface**, depuis Java 8+, c'est un contrat de comportement. Elle définit ce qu'un objet *peut faire*, pas ce qu'il *est*. Une classe peut implémenter plusieurs interfaces, ce qui permet une forme de multi-héritage de comportements.

**Exemple avec interface:**
```java
public interface Reservable {
    boolean reserveCapacity(int quantity);
    void releaseCapacity(int quantity);
    int getAvailableCapacity();
}

public interface Publishable {
    void publish();
    void unpublish();
    String getStatus();
}

// Une classe peut implémenter les deux
public class Event implements Reservable, Publishable {
    // Doit implémenter toutes les méthodes des deux interfaces
}
```

**Quand utiliser quoi?** J'utilise une classe abstraite quand j'ai du code commun à partager et une relation 'est-un' (Event *est une* BaseEntity). J'utilise une interface quand je veux définir une capacité que plusieurs classes non-liées peuvent avoir (un Event et un Venue peuvent tous deux être Reservable)."

---

### Q3: Comment fonctionne le Garbage Collector en Java?

**Réponse narrative:**

"Le Garbage Collector, ou GC, c'est la raison pour laquelle on n'a pas de `malloc` et `free` en Java comme en C. La JVM gère automatiquement la mémoire pour nous.

Le principe est simple : le GC identifie les objets qui ne sont plus accessibles — ceux qu'aucune référence ne pointe — et libère leur mémoire. Mais l'implémentation est sophistiquée.

**La mémoire est divisée en générations:**

1. **Young Generation** : où les nouveaux objets sont créés. La plupart des objets meurent jeunes (variables locales, objets temporaires). Le GC ici est fréquent mais rapide (Minor GC).

2. **Old Generation** : les objets qui survivent plusieurs cycles du Young GC sont promus ici. Le GC est moins fréquent mais plus coûteux (Major GC).

3. **Metaspace** : stocke les métadonnées des classes (remplace PermGen depuis Java 8).

**Exemple de mon projet:**
```java
public ReservationResponse createReservation(CreateReservationRequest request) {
    // Cet objet 'reservation' vit dans le Young Generation
    Reservation reservation = Reservation.builder()
        .userId(request.getUserId())
        .eventId(request.getEventId())
        .build();
    
    // Après save(), l'objet peut être promu en Old Generation
    // s'il reste référencé longtemps (ex: dans un cache)
    reservation = reservationRepository.save(reservation);
    
    // L'objet 'response' est créé, retourné, puis devient éligible au GC
    // quand le client a fini de le traiter
    return mapToResponse(reservation);
}
```

**Impact en production:** J'ai configuré mes conteneurs Docker avec des options JVM appropriées comme `-XX:+UseG1GC` pour le garbage collector G1 (adapté aux applications avec de grands heaps) et `-Xmx512m` pour limiter la mémoire heap."

---

### Q4: Qu'est-ce que les Streams en Java et pourquoi les utiliser?

**Réponse narrative:**

"Les Streams, introduits en Java 8, ont complètement changé ma façon d'écrire du code. Avant, pour transformer une liste, on écrivait des boucles for avec des variables temporaires. Maintenant, on peut exprimer les transformations de façon déclarative et fluide.

Un Stream, c'est une séquence d'éléments sur laquelle on peut appliquer des opérations en chaîne. Il y a deux types d'opérations :
- **Intermédiaires** : `filter()`, `map()`, `sorted()` — elles retournent un nouveau Stream
- **Terminales** : `collect()`, `forEach()`, `count()` — elles produisent un résultat et ferment le Stream

**Exemple réel de mon ReservationService:**
```java
@Transactional(readOnly = true)
public List<ReservationResponse> getUserReservations(Long userId) {
    List<Reservation> reservations = reservationRepository.findByUserId(userId);
    
    // Avant Java 8 (boucle impérative)
    List<ReservationResponse> responses = new ArrayList<>();
    for (Reservation reservation : reservations) {
        responses.add(mapToResponse(reservation));
    }
    return responses;
    
    // Avec Streams (style déclaratif)
    return reservations.stream()
            .map(this::mapToResponse)  // Transforme chaque Reservation en Response
            .collect(Collectors.toList());
}
```

**Exemple plus complexe avec filtrage:**
```java
// Trouver les événements publiés dans une ville spécifique, triés par date
List<EventResponse> searchEvents(String city) {
    return eventRepository.findAll().stream()
            .filter(event -> "PUBLISHED".equals(event.getStatus()))
            .filter(event -> city.equalsIgnoreCase(event.getCity()))
            .sorted(Comparator.comparing(Event::getStartDate))
            .map(this::mapToResponse)
            .collect(Collectors.toList());
}
```

**Les avantages que j'ai constatés:**
1. **Lisibilité** : le code exprime l'intention, pas la mécanique
2. **Parallélisation** : `.parallelStream()` pour traiter en parallèle sans effort
3. **Lazy evaluation** : les opérations ne s'exécutent qu'au terminal, permettant des optimisations"

---

### Q5: Expliquez les principes SOLID avec des exemples?

**Réponse narrative:**

"SOLID, ce sont cinq principes de conception orientée objet qui m'aident à écrire du code maintenable. Je vais les illustrer avec des exemples de mon projet.

---

**S - Single Responsibility Principle (Responsabilité unique)**

Chaque classe doit avoir une seule raison de changer. Dans mon projet, j'ai séparé les responsabilités :

```java
// ❌ Mauvais : une classe qui fait tout
public class EventManager {
    public void createEvent() { }
    public void sendEmail() { }
    public void processPayment() { }
}

// ✅ Bon : responsabilités séparées
public class EventService { /* gestion des événements */ }
public class NotificationService { /* envoi d'emails */ }
public class PaymentService { /* traitement des paiements */ }
```

---

**O - Open/Closed Principle (Ouvert/Fermé)**

Le code doit être ouvert à l'extension mais fermé à la modification.

```java
// Exemple : ajouter de nouveaux types de notification sans modifier le code existant
public interface NotificationSender {
    void send(String message, String recipient);
}

public class EmailSender implements NotificationSender { }
public class SmsSender implements NotificationSender { }
// Nouveau type : juste ajouter une classe, pas modifier les existantes
public class PushNotificationSender implements NotificationSender { }
```

---

**L - Liskov Substitution Principle (Substitution de Liskov)**

Une classe enfant doit pouvoir remplacer sa classe parent sans casser le programme.

```java
// ✅ Bon exemple dans mon projet
public class Reservation {
    public boolean isPending() { return "PENDING".equals(status); }
}

// Je peux utiliser n'importe quelle Reservation sans connaître sa sous-classe
public void processReservation(Reservation reservation) {
    if (reservation.isPending()) {
        // Fonctionne avec Reservation ou toute sous-classe
    }
}
```

---

**I - Interface Segregation Principle (Ségrégation des interfaces)**

Les clients ne doivent pas dépendre d'interfaces qu'ils n'utilisent pas.

```java
// ❌ Interface trop large
public interface EventOperations {
    void create();
    void update();
    void delete();
    void sendNotification();  // Pas toutes les classes en ont besoin
    void processPayment();     // Idem
}

// ✅ Interfaces séparées
public interface CrudOperations<T> { void create(); void update(); void delete(); }
public interface Notifiable { void sendNotification(); }
public interface Payable { void processPayment(); }
```

---

**D - Dependency Inversion Principle (Inversion des dépendances)**

Dépendre des abstractions, pas des implémentations concrètes.

```java
// ✅ Mon ReservationService dépend d'une interface, pas d'une implémentation
@Service
@RequiredArgsConstructor
public class ReservationService {
    // Injecté via interface Optional pour flexibilité
    private final Optional<EventServiceClient> eventServiceClient;
    
    // Je peux facilement substituer un mock ou une autre implémentation
}
```

Ces principes me guident quotidiennement pour éviter le code spaghetti et faciliter les évolutions futures."

---

## 🌐 SPRING FRAMEWORK

---

### Q6: Qu'est-ce que l'Inversion de Contrôle (IoC) et l'Injection de Dépendances (DI)?

**Réponse narrative:**

"L'IoC et la DI sont au cœur de Spring, et comprendre ces concepts a vraiment changé ma façon de structurer mes applications.

**L'Inversion de Contrôle**, c'est un principe où le framework prend le contrôle du cycle de vie des objets à ma place. Au lieu que ma classe crée ses propres dépendances (avec `new`), elle les déclare et le framework les lui fournit.

**L'Injection de Dépendances** est la technique utilisée pour implémenter l'IoC.

**Exemple concret - avant IoC (couplage fort):**
```java
public class EventController {
    // Je crée moi-même ma dépendance = couplage fort
    private EventService eventService = new EventService(
        new EventRepository(),
        new EventCapacityRepository()
    );
}
```

**Problèmes :**
- Difficile à tester (comment mocker EventService ?)
- Si EventService change de constructeur, je dois modifier EventController
- Pas de gestion du cycle de vie (singleton, prototype...)

**Avec Spring IoC/DI:**
```java
@RestController
@RequiredArgsConstructor  // Génère le constructeur avec tous les champs final
public class EventController {
    
    private final EventService eventService;  // Injecté par Spring
    
    @PostMapping
    public ResponseEntity<EventResponse> createEvent(@RequestBody CreateEventRequest request) {
        // J'utilise eventService sans savoir comment il a été créé
        return ResponseEntity.ok(eventService.createEvent(request));
    }
}
```

**Comment Spring résout les dépendances :**
1. Au démarrage, Spring scanne les classes annotées (@Component, @Service, @Repository, @Controller)
2. Il crée des **beans** — des instances gérées par le conteneur
3. Quand une classe a besoin d'une dépendance, Spring l'injecte automatiquement

**Les trois types d'injection :**
```java
// 1. Par constructeur (RECOMMANDÉ - que j'utilise)
@RequiredArgsConstructor
public class EventService {
    private final EventRepository repository;  // Immutable, facile à tester
}

// 2. Par setter
@Service
public class EventService {
    private EventRepository repository;
    
    @Autowired
    public void setRepository(EventRepository repository) {
        this.repository = repository;
    }
}

// 3. Par champ (DÉCONSEILLÉ)
@Service
public class EventService {
    @Autowired
    private EventRepository repository;  // Difficile à tester
}
```

**Avantage pour les tests :**
```java
@Test
void shouldCreateEvent() {
    // Je peux facilement injecter un mock
    EventRepository mockRepo = mock(EventRepository.class);
    EventService service = new EventService(mockRepo);
    
    // Mon test est isolé et rapide
}
```

C'est vraiment un changement de paradigme qui rend le code plus modulaire et testable."

---

### Q7: Expliquez le cycle de vie d'un Bean Spring?

**Réponse narrative:**

"Le cycle de vie d'un bean Spring est plus riche qu'un simple `new Object()`. Spring offre plusieurs points d'extension pour exécuter du code à différentes étapes.

**Les étapes principales :**

1. **Instanciation** : Spring crée l'instance avec le constructeur
2. **Population des propriétés** : les dépendances sont injectées
3. **Callbacks d'initialisation** : méthodes @PostConstruct, InitializingBean
4. **Le bean est prêt** : utilisable par l'application
5. **Callbacks de destruction** : méthodes @PreDestroy, DisposableBean
6. **Le bean est détruit** : garbage collected

**Exemple pratique dans mon projet :**
```java
@Service
@Slf4j
public class JwtService {

    @Value("${jwt.secret}")
    private String jwtSecret;
    
    @Value("${jwt.expiration}")
    private Long jwtExpiration;
    
    private SecretKey signingKey;
    
    // Exécuté APRÈS l'injection des dépendances
    @PostConstruct
    public void init() {
        log.info("Initializing JWT Service...");
        // Pré-calculer la clé de signature pour éviter de le faire à chaque token
        this.signingKey = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
        log.info("JWT Service initialized with expiration: {} ms", jwtExpiration);
    }
    
    // Exécuté AVANT la destruction du bean (shutdown de l'application)
    @PreDestroy
    public void cleanup() {
        log.info("Shutting down JWT Service, clearing sensitive data...");
        this.signingKey = null;
    }
    
    public String generateToken(Long userId, String email, Set<String> roles) {
        return Jwts.builder()
                .signWith(signingKey)  // Utilise la clé pré-calculée
                .compact();
    }
}
```

**Les scopes de beans :**
```java
@Component
@Scope("singleton")  // Par défaut - une seule instance partagée
public class EventService { }

@Component
@Scope("prototype")  // Nouvelle instance à chaque injection
public class RequestContext { }

@Component
@Scope("request")  // Une instance par requête HTTP
public class RequestLogger { }
```

Dans mon projet, tous mes services sont des singletons — c'est suffisant car ils sont stateless (pas d'état entre les requêtes)."

---

### Q8: Comment fonctionne Spring Data JPA?

**Réponse narrative:**

"Spring Data JPA est une couche d'abstraction au-dessus de JPA/Hibernate qui élimine énormément de code boilerplate. L'idée géniale, c'est que je n'écris que des interfaces, et Spring génère l'implémentation automatiquement.

**Exemple de mon EventRepository :**
```java
@Repository
public interface EventRepository extends JpaRepository<Event, Long> {
    
    // Méthode générée automatiquement à partir du nom !
    List<Event> findByOrganizerId(Long organizerId);
    
    // Spring parse "findBy + Status + OrderBy + StartDate + Asc"
    Page<Event> findByStatusOrderByStartDateAsc(String status, Pageable pageable);
    
    // Pour des requêtes complexes, j'utilise @Query
    @Query("SELECT e FROM Event e WHERE e.city = :city AND e.status = 'PUBLISHED'")
    List<Event> findPublishedEventsInCity(@Param("city") String city);
}
```

**Ce que JpaRepository me donne gratuitement :**
- `save(entity)` — insert ou update intelligent
- `findById(id)` — retourne Optional<T>
- `findAll()` / `findAll(Pageable)` — avec pagination
- `delete(entity)` / `deleteById(id)`
- `count()` / `existsById(id)`

**Conventions de nommage :**
```java
// Spring génère le SQL à partir du nom de la méthode
List<Event> findByTitleContaining(String keyword);
// → SELECT * FROM events WHERE title LIKE '%keyword%'

List<Event> findByStartDateAfterAndStatus(LocalDateTime date, String status);
// → SELECT * FROM events WHERE start_date > ? AND status = ?

Optional<Event> findFirstByOrganizerIdOrderByCreatedAtDesc(Long organizerId);
// → SELECT * FROM events WHERE organizer_id = ? ORDER BY created_at DESC LIMIT 1
```

**Gestion des transactions :**
```java
@Service
@Transactional  // Toutes les méthodes sont transactionnelles
public class EventService {
    
    @Transactional(readOnly = true)  // Optimise les lectures
    public EventResponse getEvent(Long eventId) {
        return eventRepository.findById(eventId)
            .map(this::mapToResponse)
            .orElseThrow(() -> new ResourceNotFoundException("Event not found"));
    }
    
    // Méthode d'écriture - utilise la transaction par défaut
    public EventResponse createEvent(CreateEventRequest request) {
        Event event = eventRepository.save(buildEvent(request));
        return mapToResponse(event);
    }
}
```

**Locking pour la concurrence (dans mon projet):**
```java
@Repository
public interface EventCapacityRepository extends JpaRepository<EventCapacity, Long> {
    
    // Pessimistic lock pour éviter les conditions de course
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM EventCapacity c WHERE c.eventId = :eventId")
    EventCapacity findByEventIdWithLock(@Param("eventId") Long eventId);
}
```

Avec Spring Data JPA, mon code de persistence est réduit de 80% par rapport à du JDBC pur, tout en restant type-safe et performant."

---

## 🏗️ ARCHITECTURE & MICROSERVICES

---

### Q9: Pourquoi choisir une architecture microservices plutôt que monolithique?

**Réponse narrative:**

"C'est une question que je me suis posée au début de mon projet. Un monolithe n'est pas mauvais en soi — pour une petite équipe ou un MVP, c'est souvent le bon choix. Mais pour une plateforme d'événements qui doit scaler, les microservices apportent des avantages significatifs.

**Les raisons de mon choix :**

**1. Scalabilité ciblée**
Pendant un concert ou un événement populaire, mon service de réservation va recevoir 100x plus de trafic que le service utilisateur. Avec des microservices, je peux scaler uniquement le ReservationService à 10 instances, tandis que le UserService reste à 2 instances.

```yaml
# Kubernetes - scaling indépendant
reservation-service:
  replicas: 10  # Haute charge
user-service:
  replicas: 2   # Charge normale
```

**2. Déploiement indépendant**
Si je dois corriger un bug dans le paiement, je redéploie uniquement PaymentService. Les utilisateurs peuvent continuer à naviguer les événements et faire des réservations pendant ce temps.

**3. Isolation des pannes**
Si le service de notification tombe (problème SMTP), les réservations continuent de fonctionner. J'ai implémenté ça avec des fallbacks :

```java
private void releaseCapacitySafely(Long eventId, int quantity) {
    if (eventServiceClient.isEmpty()) {
        log.warn("Event Service unavailable, skipping capacity release");
        return;  // Ne pas bloquer le processus principal
    }
    // ...
}
```

**4. Équipes autonomes**
Chaque équipe peut être responsable d'un service de bout en bout : développement, tests, déploiement, monitoring. Pas de coordination complexe entre équipes.

**5. Technologie adaptée**
Même si j'utilise Java partout actuellement, rien ne m'empêche d'écrire le service de recherche en Python avec Elasticsearch, ou le service de notifications en Node.js pour les WebSockets.

**Les compromis acceptés :**

- **Complexité opérationnelle** : j'ai 5 services à déployer, monitorer, debugger
- **Latence réseau** : chaque appel inter-service ajoute quelques millisecondes
- **Transactions distribuées** : pas de simple `@Transactional`, je dois implémenter le pattern Saga
- **Debugging** : suivre une requête à travers 4 services nécessite du correlation ID et du tracing

Pour mon projet, les bénéfices l'emportent largement sur les inconvénients."

---

### Q10: Comment gérez-vous la communication entre microservices?

**Réponse narrative:**

"Dans mon projet, j'ai principalement de la communication **synchrone** via REST, mais le choix dépend du cas d'usage.

**Communication Synchrone (REST via OpenFeign) :**

C'est ce que j'utilise quand j'ai besoin d'une réponse immédiate.

```java
@FeignClient(name = "event-service", url = "${event-service.url:http://localhost:8082}")
public interface EventServiceClient {
    
    @GetMapping("/events/{eventId}/availability")
    EventAvailabilityResponse getEventAvailability(@PathVariable Long eventId);
    
    @PostMapping("/events/{eventId}/reserve")
    ReservationResultResponse reserveCapacity(
        @PathVariable Long eventId, 
        @RequestParam int quantity
    );
}
```

**Utilisation dans ReservationService :**
```java
public ReservationResponse createReservation(CreateReservationRequest request) {
    // 1. Vérifier la disponibilité (appel synchrone)
    EventAvailabilityResponse availability = 
        eventServiceClient.getEventAvailability(request.getEventId());
    
    if (availability.availableCapacity() < request.getQuantity()) {
        throw new IllegalStateException("Pas assez de places");
    }
    
    // 2. Réserver la capacité (appel synchrone)
    ReservationResultResponse result = 
        eventServiceClient.reserveCapacity(request.getEventId(), request.getQuantity());
    
    // 3. Créer la réservation localement
    // ...
}
```

**Communication Asynchrone (pour le futur) :**

Pour les notifications, je prévois d'utiliser un message broker comme RabbitMQ ou Kafka :

```java
// Producteur (ReservationService)
@Autowired
private RabbitTemplate rabbitTemplate;

public ReservationResponse confirmReservation(String reservationId) {
    Reservation reservation = confirm(reservationId);
    
    // Envoyer un message async - pas besoin d'attendre la réponse
    rabbitTemplate.convertAndSend("notifications", 
        new ReservationConfirmedEvent(reservation.getUserId(), reservation.getId()));
    
    return mapToResponse(reservation);
}

// Consommateur (NotificationService)
@RabbitListener(queues = "notifications")
public void handleReservationConfirmed(ReservationConfirmedEvent event) {
    // Envoyer l'email de confirmation
    emailService.sendConfirmation(event.getUserId(), event.getReservationId());
}
```

**Quand utiliser quoi :**

| Cas d'usage | Type | Raison |
|-------------|------|--------|
| Vérifier disponibilité | Synchrone | Réponse immédiate nécessaire |
| Réserver capacité | Synchrone | Transaction business critique |
| Envoyer notification | Asynchrone | Peut être retardé, pas bloquant |
| Générer rapport | Asynchrone | Traitement long, pas urgent |

**Résilience avec fallbacks :**
```java
private EventServiceClient.EventResponse getEventSafely(Long eventId) {
    try {
        return eventServiceClient.getEvent(eventId);
    } catch (FeignException e) {
        log.error("Event Service down, using cached/default data");
        return new EventResponse(eventId, "Default Event", "PUBLISHED", 100, BigDecimal.valueOf(29.99));
    }
}
```

Cette approche hybride me permet d'avoir la cohérence quand c'est critique, et la découplage quand c'est acceptable."

---

## 🔧 DEVOPS & INFRASTRUCTURE

---

### Q11: Expliquez Docker et la conteneurisation?

**Réponse narrative:**

"Docker a révolutionné la façon dont je déploie mes applications. Avant les conteneurs, le fameux 'ça marche sur ma machine' était un vrai problème. Avec Docker, je package mon application avec toutes ses dépendances dans une image portable.

**Concept clé :**
Un conteneur Docker, c'est comme une VM légère, mais au lieu de virtualiser le hardware complet, il partage le kernel de l'hôte. C'est beaucoup plus léger — mon image de microservice fait ~150MB et démarre en 2 secondes.

**Mon Dockerfile multi-stage :**
```dockerfile
# Stage 1: Build
FROM maven:3.9.4-openjdk-17-slim AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
# Télécharge les dépendances et compile
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM openjdk:17-jre-slim
WORKDIR /app
# Copie seulement le JAR, pas Maven ni les sources
COPY --from=build /app/target/*.jar app.jar

# L'utilisateur non-root pour la sécurité
RUN addgroup --system appgroup && adduser --system appuser --ingroup appgroup
USER appuser

EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Pourquoi multi-stage ?**
L'image de build (Maven + JDK) fait ~800MB. L'image finale (JRE seul + JAR) fait ~150MB. En production, je ne paie que pour ce qui est nécessaire.

**Mon docker-compose.yml pour le développement :**
```yaml
version: '3.8'
services:
  postgres-event:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: eventdb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5433:5432"
    volumes:
      - postgres-event-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes

volumes:
  postgres-event-data:
```

**Commandes quotidiennes :**
```bash
# Démarrer l'infrastructure
docker-compose up -d

# Voir les logs d'un service
docker-compose logs -f postgres-event

# Rebuild après modification
docker-compose build event-service
docker-compose up -d event-service

# Nettoyer
docker-compose down -v  # Supprime aussi les volumes
```

Docker me garantit que l'environnement de développement est identique à la production — plus de surprises au déploiement."

---

### Q12: Comment fonctionne un pipeline CI/CD?

**Réponse narrative:**

"CI/CD, c'est l'automatisation de tout ce qui se passe entre un `git push` et le déploiement en production. L'objectif est de détecter les problèmes le plus tôt possible et de livrer rapidement.

**CI (Continuous Integration) :**
À chaque commit, le code est automatiquement compilé, testé, analysé.

**CD (Continuous Delivery/Deployment) :**
Le code validé est automatiquement préparé (voire déployé) vers les environnements.

**Mon pipeline GitHub Actions :**

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  # Job 1: Tests et qualité
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Java 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven
      
      - name: Run Tests
        run: mvn test
      
      - name: Code Coverage
        run: mvn jacoco:report
      
      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3

  # Job 2: Build Docker images
  build:
    needs: test  # S'exécute seulement si les tests passent
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [user-service, event-service, reservation-service, payment-service]
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker Image
        run: docker build -t myregistry/${{ matrix.service }}:${{ github.sha }} ./${{ matrix.service }}
      
      - name: Push to Registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push myregistry/${{ matrix.service }}:${{ github.sha }}

  # Job 3: Deploy (uniquement sur main)
  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/event-service \
            event-service=myregistry/event-service:${{ github.sha }}
```

**Les étapes critiques :**

1. **Tests automatisés** — si un test échoue, le pipeline s'arrête immédiatement
2. **Analyse de code** — SonarQube pour la qualité, Snyk pour les vulnérabilités
3. **Build d'images** — images Docker versionnées avec le SHA du commit
4. **Déploiement progressif** — rolling update pour zero-downtime

**Bonnes pratiques que j'applique :**
- Tests rapides d'abord (unit tests), puis lents (integration tests)
- Cache des dépendances Maven pour accélérer
- Secrets stockés dans GitHub Secrets, jamais dans le code
- Tags d'images avec SHA (traçabilité) + tag `latest` pour faciliter le dev"

---

### Q13: Comment déploieriez-vous sur Kubernetes?

**Réponse narrative:**

"Kubernetes orchestre mes conteneurs en production. Il gère le déploiement, le scaling, le load balancing, et la récupération automatique en cas de panne.

**Les ressources Kubernetes pour mon Event Service :**

**1. Deployment — gère les pods**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: event-service
spec:
  replicas: 3  # Haute disponibilité
  selector:
    matchLabels:
      app: event-service
  template:
    metadata:
      labels:
        app: event-service
    spec:
      containers:
      - name: event-service
        image: myregistry/event-service:1.0.0
        ports:
        - containerPort: 8082
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8082
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8082
          initialDelaySeconds: 10
          periodSeconds: 5
```

**2. Service — expose et load-balance**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: event-service
spec:
  selector:
    app: event-service
  ports:
  - port: 8082
    targetPort: 8082
  type: ClusterIP  # Interne au cluster
```

**3. Ingress — expose vers l'extérieur**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-gateway-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - api.eventplatform.com
    secretName: tls-secret
  rules:
  - host: api.eventplatform.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 8080
```

**4. HorizontalPodAutoscaler — scaling automatique**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: event-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: event-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
```

**Ce que Kubernetes me donne :**
- **Self-healing** : si un pod crash, il est automatiquement recréé
- **Rolling updates** : déploiement progressif sans interruption
- **Service discovery** : les services se trouvent par nom DNS
- **Scaling** : manuel avec `kubectl scale` ou automatique avec HPA
- **Secrets management** : credentials injectés sans les mettre dans le code"

---

### Q14: Comment assurez-vous la surveillance et le monitoring?

**Réponse narrative:**

"Le monitoring est crucial en microservices — avec 5 services, les problèmes peuvent venir de partout. J'ai une stratégie basée sur les trois piliers de l'observabilité : logs, metrics, et traces.

**1. Logs structurés :**

J'utilise Logback avec un format JSON pour faciliter l'indexation dans ELK ou Loki :

```java
@Slf4j
@RestController
public class EventController {
    
    @PostMapping
    public ResponseEntity<EventResponse> createEvent(@RequestBody CreateEventRequest request) {
        log.info("Creating event: title={}, organizer={}", 
            request.getTitle(), request.getOrganizerId());
        
        try {
            EventResponse response = eventService.createEvent(request);
            log.info("Event created successfully: eventId={}", response.getId());
            return ResponseEntity.status(CREATED).body(response);
        } catch (Exception e) {
            log.error("Failed to create event: title={}, error={}", 
                request.getTitle(), e.getMessage(), e);
            throw e;
        }
    }
}
```

**Correlation ID pour tracer les requêtes :**
```java
@Component
public class CorrelationIdFilter extends OncePerRequestFilter {
    
    @Override
    protected void doFilterInternal(HttpServletRequest request, ...) {
        String correlationId = request.getHeader("X-Correlation-ID");
        if (correlationId == null) {
            correlationId = UUID.randomUUID().toString();
        }
        MDC.put("correlationId", correlationId);  // Ajouté à tous les logs
        // ...
    }
}
```

**2. Metrics avec Spring Actuator :**

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus,metrics
  endpoint:
    health:
      show-details: always
      probes:
        enabled: true  # Pour Kubernetes liveness/readiness
```

**Endpoints disponibles :**
- `/actuator/health` — état du service et dépendances (DB, Redis)
- `/actuator/prometheus` — metrics au format Prometheus (requêtes HTTP, JVM, custom)
- `/actuator/metrics/http.server.requests` — latence, status codes

**Metrics custom :**
```java
@Service
@RequiredArgsConstructor
public class ReservationService {
    
    private final MeterRegistry meterRegistry;
    
    public ReservationResponse createReservation(CreateReservationRequest request) {
        Timer.Sample sample = Timer.start(meterRegistry);
        try {
            ReservationResponse response = doCreateReservation(request);
            meterRegistry.counter("reservations.created", 
                "status", "success").increment();
            return response;
        } catch (Exception e) {
            meterRegistry.counter("reservations.created", 
                "status", "failed", "reason", e.getClass().getSimpleName()).increment();
            throw e;
        } finally {
            sample.stop(meterRegistry.timer("reservations.create.duration"));
        }
    }
}
```

**3. Stack de monitoring typique :**

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Services  │────▶│  Prometheus │────▶│   Grafana   │
│  (metrics)  │     │  (scraping) │     │ (dashboards)│
└─────────────┘     └─────────────┘     └─────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Services  │────▶│   Fluentd   │────▶│   Kibana    │
│   (logs)    │     │ (collection)│     │  (search)   │
└─────────────┘     └─────────────┘     └─────────────┘
```

**Alerting :**
Je configure des alertes dans Prometheus/Grafana :
- Taux d'erreur HTTP > 5% pendant 5 minutes
- Latence P99 > 1 seconde
- CPU > 80% pendant 10 minutes
- Pods restarts > 3 en 1 heure

Le monitoring n'est pas un luxe — c'est ce qui me permet de dormir tranquille quand l'application est en production."

---

## 💡 Conseils pour l'Oral

1. **Commencez par le contexte** — "Dans mon projet, j'ai rencontré ce problème..."
2. **Donnez des exemples concrets** — montrez que vous avez vraiment pratiqué
3. **Mentionnez les trade-offs** — ça montre de la maturité technique
4. **Admettez ce que vous ne savez pas** — "Je n'ai pas encore implémenté ça, mais voici comment je le ferais..."
5. **Posez des questions en retour** — "Comment gérez-vous ça chez vous ?"
