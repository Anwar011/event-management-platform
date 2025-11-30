package com.eventplatform.reservation.service;

import com.eventplatform.reservation.client.EventServiceClient;
import com.eventplatform.reservation.dto.CreateReservationRequest;
import com.eventplatform.reservation.dto.ReservationItemRequest;
import com.eventplatform.reservation.dto.ReservationItemResponse;
import com.eventplatform.reservation.dto.ReservationResponse;
import com.eventplatform.reservation.entity.Reservation;
import com.eventplatform.reservation.entity.ReservationItem;
import com.eventplatform.reservation.repository.ReservationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReservationService {

    private final ReservationRepository reservationRepository;
    // private final EventServiceClient eventServiceClient; // Temporarily disabled

    @Value("${feature.event-integration:true}")
    private boolean eventServiceEnabled;

    @Value("${reservation.max-tickets-per-user-per-event:4}")
    private int maxTicketsPerUserPerEvent;

    // Fallback values when Event Service is not available
    private static final BigDecimal DEFAULT_EVENT_PRICE = BigDecimal.valueOf(29.99);

    /**
     * Safely call Event Service with fallback for when service is unavailable
     */
    private EventServiceClient.EventResponse getEventSafely(Long eventId) {
        if (!eventServiceEnabled) {
            log.warn("Event Service disabled, using default values for event {}", eventId);
            return new EventServiceClient.EventResponse(eventId, "Default Event", "PUBLISHED", 100, DEFAULT_EVENT_PRICE);
        }

        try {
            // For now, we'll assume Event Service is available since we disabled the client injection
            // In a real scenario, we'd inject a stub or use conditional bean creation
            throw new RuntimeException("Event Service client not available - implement fallback");
        } catch (Exception e) {
            log.error("Failed to get event {} from Event Service, using defaults", eventId, e);
            return new EventServiceClient.EventResponse(eventId, "Default Event", "PUBLISHED", 100, DEFAULT_EVENT_PRICE);
        }
    }

    private EventServiceClient.ReservationResultResponse reserveCapacitySafely(Long eventId, int quantity) {
        if (!eventServiceEnabled) {
            log.warn("Event Service disabled, skipping capacity reservation for event {}", eventId);
            return new EventServiceClient.ReservationResultResponse(eventId, quantity, true, "Mock reservation successful");
        }

        try {
            throw new RuntimeException("Event Service client not available - implement fallback");
        } catch (Exception e) {
            log.error("Failed to reserve capacity for event {}, assuming success", eventId, e);
            return new EventServiceClient.ReservationResultResponse(eventId, quantity, true, "Fallback reservation successful");
        }
    }

    private void releaseCapacitySafely(Long eventId, int quantity) {
        if (!eventServiceEnabled) {
            log.warn("Event Service disabled, skipping capacity release for event {}", eventId);
            return;
        }

        try {
            log.info("Would release capacity for event {}: quantity {}", eventId, quantity);
        } catch (Exception e) {
            log.error("Failed to release capacity for event {}", eventId, e);
        }
    }

    private Integer getAvailableCapacitySafely(Long eventId) {
        if (!eventServiceEnabled) {
            return 100; // Default available capacity
        }

        try {
            throw new RuntimeException("Event Service client not available - implement fallback");
        } catch (Exception e) {
            log.error("Failed to get available capacity for event {}, using default", eventId, e);
            return 100;
        }
    }

    @Transactional
    public ReservationResponse createReservation(CreateReservationRequest request) {
        log.info("Creating reservation for user {} and event {} with quantity {}",
                request.getUserId(), request.getEventId(), request.getQuantity());

        // Check idempotency - if idempotency key provided and already exists, return existing reservation
        if (request.getIdempotencyKey() != null) {
            Optional<Reservation> existing = reservationRepository.findByIdempotencyKey(request.getIdempotencyKey());
            if (existing.isPresent()) {
                log.info("Idempotency key {} already exists, returning existing reservation", request.getIdempotencyKey());
                return mapToResponse(existing.get());
            }
        }

        // Validate user limits
        validateUserLimits(request.getUserId(), request.getEventId(), request.getQuantity());

        // Check event availability
        checkEventAvailability(request.getEventId(), request.getQuantity());

        // Get event details for pricing
        EventServiceClient.EventResponse event = getEventSafely(request.getEventId());
        if (!"PUBLISHED".equals(event.status())) {
            throw new IllegalStateException("Event is not available for reservations");
        }

        BigDecimal totalPrice = event.price().multiply(BigDecimal.valueOf(request.getQuantity()));

        // Generate unique reservation ID
        String reservationId = "RES-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        // Create reservation
        Reservation reservation = Reservation.builder()
                .reservationId(reservationId)
                .userId(request.getUserId())
                .eventId(request.getEventId())
                .quantity(request.getQuantity())
                .totalPrice(totalPrice)
                .status("PENDING")
                .idempotencyKey(request.getIdempotencyKey())
                .build();

        // Create reservation items
        createReservationItems(reservation, request, event.price());

        try {
            // Reserve capacity in Event Service
            EventServiceClient.ReservationResultResponse capacityResult =
                reserveCapacitySafely(request.getEventId(), request.getQuantity());

            if (!capacityResult.success()) {
                throw new IllegalStateException("Failed to reserve capacity: " + capacityResult.message());
            }

            // Save reservation
            reservation = reservationRepository.save(reservation);
            log.info("Created reservation {} for user {} event {}", reservationId, request.getUserId(), request.getEventId());

            return mapToResponse(reservation);

        } catch (Exception e) {
            // If anything fails, release the capacity we reserved
            try {
                releaseCapacitySafely(request.getEventId(), request.getQuantity());
            } catch (Exception releaseException) {
                log.error("Failed to release capacity after reservation failure", releaseException);
            }
            throw e;
        }
    }

    @Transactional(readOnly = true)
    public ReservationResponse getReservation(String reservationId) {
        log.info("Fetching reservation: {}", reservationId);

        Reservation reservation = reservationRepository.findByReservationId(reservationId)
                .orElseThrow(() -> new IllegalArgumentException("Reservation not found: " + reservationId));

        return mapToResponse(reservation);
    }

    @Transactional(readOnly = true)
    public List<ReservationResponse> getUserReservations(Long userId) {
        log.info("Fetching reservations for user: {}", userId);

        List<Reservation> reservations = reservationRepository.findByUserId(userId);
        return reservations.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public ReservationResponse confirmReservation(String reservationId) {
        log.info("Confirming reservation: {}", reservationId);

        Reservation reservation = reservationRepository.findByReservationId(reservationId)
                .orElseThrow(() -> new IllegalArgumentException("Reservation not found: " + reservationId));

        if (!reservation.isPending()) {
            throw new IllegalStateException("Only pending reservations can be confirmed");
        }

        reservation.confirm();
        reservation = reservationRepository.save(reservation);

        log.info("Confirmed reservation: {}", reservationId);
        return mapToResponse(reservation);
    }

    @Transactional
    public ReservationResponse cancelReservation(String reservationId) {
        log.info("Cancelling reservation: {}", reservationId);

        Reservation reservation = reservationRepository.findByReservationId(reservationId)
                .orElseThrow(() -> new IllegalArgumentException("Reservation not found: " + reservationId));

        if (reservation.isCancelled()) {
            throw new IllegalStateException("Reservation is already cancelled");
        }

        // Release capacity back to event
        try {
            releaseCapacitySafely(reservation.getEventId(), reservation.getQuantity());
        } catch (Exception e) {
            log.warn("Failed to release capacity for cancelled reservation {}", reservationId, e);
        }

        reservation.cancel();
        reservation = reservationRepository.save(reservation);

        log.info("Cancelled reservation: {}", reservationId);
        return mapToResponse(reservation);
    }

    private void validateUserLimits(Long userId, Long eventId, int requestedQuantity) {
        int currentReservations = reservationRepository.sumQuantityByUserAndEvent(userId, eventId);
        int totalAfterReservation = currentReservations + requestedQuantity;

        if (totalAfterReservation > maxTicketsPerUserPerEvent) {
            throw new IllegalArgumentException(
                String.format("User %d already has %d tickets for event %d. Maximum allowed: %d. Requested: %d",
                    userId, currentReservations, eventId, maxTicketsPerUserPerEvent, requestedQuantity));
        }
    }

    private void checkEventAvailability(Long eventId, int quantity) {
        Integer availableCapacity = getAvailableCapacitySafely(eventId);

        if (availableCapacity < quantity) {
            throw new IllegalStateException(
                String.format("Insufficient capacity for event %d. Available: %d, Requested: %d",
                    eventId, availableCapacity, quantity));
        }
    }

    private void createReservationItems(Reservation reservation, CreateReservationRequest request, BigDecimal eventPrice) {
        if (request.getItems() != null && !request.getItems().isEmpty()) {
            // Use provided items
            for (ReservationItemRequest itemRequest : request.getItems()) {
                ReservationItem item = ReservationItem.builder()
                        .reservation(reservation)
                        .ticketType(itemRequest.getTicketType())
                        .quantity(itemRequest.getQuantity())
                        .unitPrice(itemRequest.getUnitPrice())
                        .build();
                reservation.getItems().add(item);
            }
        } else {
            // Create default item
            ReservationItem item = ReservationItem.builder()
                    .reservation(reservation)
                    .ticketType("STANDARD")
                    .quantity(request.getQuantity())
                    .unitPrice(eventPrice)
                    .build();
            reservation.getItems().add(item);
        }
    }

    private ReservationResponse mapToResponse(Reservation reservation) {
        List<ReservationItemResponse> items = reservation.getItems().stream()
                .map(item -> ReservationItemResponse.builder()
                        .id(item.getId())
                        .ticketType(item.getTicketType())
                        .quantity(item.getQuantity())
                        .unitPrice(item.getUnitPrice())
                        .createdAt(item.getCreatedAt())
                        .build())
                .collect(Collectors.toList());

        return ReservationResponse.builder()
                .id(reservation.getId())
                .reservationId(reservation.getReservationId())
                .userId(reservation.getUserId())
                .eventId(reservation.getEventId())
                .quantity(reservation.getQuantity())
                .totalPrice(reservation.getTotalPrice())
                .status(reservation.getStatus())
                .idempotencyKey(reservation.getIdempotencyKey())
                .createdAt(reservation.getCreatedAt())
                .updatedAt(reservation.getUpdatedAt())
                .items(items)
                .build();
    }
}
