package com.eventplatform.reservation.repository;

import com.eventplatform.reservation.entity.Reservation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ReservationRepository extends JpaRepository<Reservation, Long> {

    // Find by reservation ID (business key)
    Optional<Reservation> findByReservationId(String reservationId);

    // Find by idempotency key (for duplicate prevention)
    Optional<Reservation> findByIdempotencyKey(String idempotencyKey);

    // Find reservations by user
    List<Reservation> findByUserId(Long userId);

    // Find reservations by event
    List<Reservation> findByEventId(Long eventId);

    // Find reservations by user and event
    List<Reservation> findByUserIdAndEventId(Long userId, Long eventId);

    // Find reservations by status
    List<Reservation> findByStatus(String status);

    // Count user's reservations for an event
    @Query("SELECT COUNT(r) FROM Reservation r WHERE r.userId = :userId AND r.eventId = :eventId AND r.status IN ('PENDING', 'CONFIRMED')")
    long countActiveReservationsByUserAndEvent(@Param("userId") Long userId, @Param("eventId") Long eventId);

    // Sum quantity of user's active reservations for an event
    @Query("SELECT COALESCE(SUM(r.quantity), 0) FROM Reservation r WHERE r.userId = :userId AND r.eventId = :eventId AND r.status IN ('PENDING', 'CONFIRMED')")
    int sumQuantityByUserAndEvent(@Param("userId") Long userId, @Param("eventId") Long eventId);

    // Check if idempotency key exists
    boolean existsByIdempotencyKey(String idempotencyKey);
}



