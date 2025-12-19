package com.eventplatform.payment.repository;

import com.eventplatform.payment.entity.PaymentIntent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentIntentRepository extends JpaRepository<PaymentIntent, Long> {

    // Find by intent ID (business key)
    Optional<PaymentIntent> findByIntentId(String intentId);

    // Find by idempotency key (for duplicate prevention)
    Optional<PaymentIntent> findByIdempotencyKey(String idempotencyKey);

    // Find by reservation ID
    List<PaymentIntent> findByReservationId(String reservationId);

    // Find by user ID
    List<PaymentIntent> findByUserId(Long userId);

    // Find by status
    List<PaymentIntent> findByStatus(String status);

    // Find expired intents
    @Query("SELECT pi FROM PaymentIntent pi WHERE pi.expiresAt < :currentTime AND pi.status NOT IN ('SUCCEEDED', 'CANCELED')")
    List<PaymentIntent> findExpiredIntents(@Param("currentTime") LocalDateTime currentTime);

    // Check if idempotency key exists
    boolean existsByIdempotencyKey(String idempotencyKey);
}





