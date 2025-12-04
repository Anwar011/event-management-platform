package com.eventplatform.payment.repository;

import com.eventplatform.payment.entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    // Find by payment ID (business key)
    Optional<Payment> findByPaymentId(String paymentId);

    // Find by intent ID
    List<Payment> findByIntentId(Long intentId);

    // Find by reservation ID
    List<Payment> findByReservationId(String reservationId);

    // Find by user ID
    List<Payment> findByUserId(Long userId);

    // Find by status
    List<Payment> findByStatus(String status);

    // Find by provider reference
    Optional<Payment> findByProviderReference(String providerReference);
}



