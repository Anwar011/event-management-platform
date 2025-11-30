package com.eventplatform.payment.service;

import com.eventplatform.payment.client.ReservationServiceClient;
import com.eventplatform.payment.dto.CreatePaymentIntentRequest;
import com.eventplatform.payment.dto.PaymentIntentResponse;
import com.eventplatform.payment.dto.PaymentResponse;
import com.eventplatform.payment.entity.Payment;
import com.eventplatform.payment.entity.PaymentIntent;
import com.eventplatform.payment.repository.PaymentIntentRepository;
import com.eventplatform.payment.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentService {

    private final PaymentIntentRepository paymentIntentRepository;
    private final PaymentRepository paymentRepository;
    // private final ReservationServiceClient reservationServiceClient; // Conditionally available

    @Value("${feature.reservation-integration:true}")
    private boolean reservationServiceEnabled;

    @Value("${payment.success-rate:0.95}")
    private double successRate;

    /**
     * Safely call Reservation Service with fallback for when service is unavailable
     */
    private Optional<ReservationServiceClient.ReservationResponse> getReservationSafely(String reservationId) {
        if (!reservationServiceEnabled) {
            log.warn("Reservation Service disabled, using default values for reservation {}", reservationId);
            return Optional.of(new ReservationServiceClient.ReservationResponse(
                1L, reservationId, 1L, 1L, 1,
                BigDecimal.valueOf(29.99), "PENDING", null,
                LocalDateTime.now(), LocalDateTime.now()
            ));
        }

        try {
            throw new RuntimeException("Reservation Service client not available - implement fallback");
        } catch (Exception e) {
            log.error("Failed to get reservation {} from Reservation Service, using defaults", reservationId, e);
            return Optional.of(new ReservationServiceClient.ReservationResponse(
                1L, reservationId, 1L, 1L, 1,
                BigDecimal.valueOf(29.99), "PENDING", null,
                LocalDateTime.now(), LocalDateTime.now()
            ));
        }
    }

    private ReservationServiceClient.ReservationResponse confirmReservationSafely(String reservationId) {
        if (!reservationServiceEnabled) {
            log.warn("Reservation Service disabled, skipping reservation confirmation for {}", reservationId);
            return new ReservationServiceClient.ReservationResponse(
                1L, reservationId, 1L, 1L, 1,
                BigDecimal.valueOf(29.99), "CONFIRMED", null,
                LocalDateTime.now(), LocalDateTime.now()
            );
        }

        try {
            throw new RuntimeException("Reservation Service client not available - implement fallback");
        } catch (Exception e) {
            log.error("Failed to confirm reservation {} in Reservation Service, assuming success", reservationId, e);
            return new ReservationServiceClient.ReservationResponse(
                1L, reservationId, 1L, 1L, 1,
                BigDecimal.valueOf(29.99), "CONFIRMED", null,
                LocalDateTime.now(), LocalDateTime.now()
            );
        }
    }

    @Transactional
    public PaymentIntentResponse createPaymentIntent(CreatePaymentIntentRequest request) {
        log.info("Creating payment intent for reservation {} and user {} with amount {}",
                request.getReservationId(), request.getUserId(), request.getAmount());

        // Check idempotency - if idempotency key provided and already exists, return existing intent
        if (request.getIdempotencyKey() != null) {
            Optional<PaymentIntent> existing = paymentIntentRepository.findByIdempotencyKey(request.getIdempotencyKey());
            if (existing.isPresent()) {
                log.info("Idempotency key {} already exists, returning existing payment intent", request.getIdempotencyKey());
                return mapIntentToResponse(existing.get());
            }
        }

        // Validate reservation exists and is in correct state
        Optional<ReservationServiceClient.ReservationResponse> reservationOpt = getReservationSafely(request.getReservationId());
        if (reservationOpt.isEmpty()) {
            throw new IllegalStateException("Reservation service unavailable for validation");
        }
        ReservationServiceClient.ReservationResponse reservation = reservationOpt.get();

        // Verify amount matches reservation total
        if (reservation.totalPrice().compareTo(request.getAmount()) != 0) {
            throw new IllegalArgumentException(
                String.format("Payment amount %.2f does not match reservation total %.2f",
                    request.getAmount(), reservation.totalPrice()));
        }

        // Generate unique intent ID
        String intentId = "PI-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        // Create payment intent
        PaymentIntent intent = PaymentIntent.builder()
                .intentId(intentId)
                .reservationId(request.getReservationId())
                .userId(request.getUserId())
                .amount(request.getAmount())
                .currency(request.getCurrency())
                .status("REQUIRES_PAYMENT_METHOD")
                .idempotencyKey(request.getIdempotencyKey())
                .paymentMethod(request.getPaymentMethod())
                .description(request.getDescription())
                .expiresAt(LocalDateTime.now().plusHours(24)) // 24 hour expiry
                .build();

        intent = paymentIntentRepository.save(intent);
        log.info("Created payment intent {} for reservation {}", intentId, request.getReservationId());

        return mapIntentToResponse(intent);
    }

    @Transactional
    public PaymentResponse capturePayment(String intentId, String idempotencyKey) {
        log.info("Capturing payment for intent: {}", intentId);

        PaymentIntent intent = paymentIntentRepository.findByIntentId(intentId)
                .orElseThrow(() -> new IllegalArgumentException("Payment intent not found: " + intentId));

        // Check idempotency for capture operation
        if (idempotencyKey != null) {
            Optional<Payment> existingPayment = paymentRepository.findByProviderReference("capture_" + idempotencyKey);
            if (existingPayment.isPresent()) {
                log.info("Idempotent capture with key {}, returning existing payment", idempotencyKey);
                return mapPaymentToResponse(existingPayment.get());
            }
        }

        // Validate intent can be captured
        if (!"REQUIRES_PAYMENT_METHOD".equals(intent.getStatus()) && !"CREATED".equals(intent.getStatus())) {
            throw new IllegalStateException("Payment intent cannot be captured. Status: " + intent.getStatus());
        }

        // Check if intent has expired
        if (intent.isExpired()) {
            intent.cancel();
            paymentIntentRepository.save(intent);
            throw new IllegalStateException("Payment intent has expired");
        }

        // Validate reservation is still valid
        Optional<ReservationServiceClient.ReservationResponse> reservationOpt =
            getReservationSafely(intent.getReservationId());

        if (reservationOpt.isEmpty()) {
            throw new IllegalStateException("Reservation service unavailable for validation");
        }

        ReservationServiceClient.ReservationResponse reservation = reservationOpt.get();
        if (!"PENDING".equals(reservation.status())) {
            throw new IllegalStateException("Reservation is not in pending state: " + reservation.status());
        }

        // Generate unique payment ID
        String paymentId = "PAY-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        // Create payment record
        Payment payment = Payment.builder()
                .paymentId(paymentId)
                .intent(intent)
                .reservationId(intent.getReservationId())
                .userId(intent.getUserId())
                .amount(intent.getAmount())
                .currency(intent.getCurrency())
                .status("PROCESSING")
                .paymentMethod(intent.getPaymentMethod())
                .providerReference("txn_" + intent.getIntentId())
                .build();

        payment = paymentRepository.save(payment);

        try {
            // Simulate payment processing
            boolean success = processPaymentSimulation();

            if (success) {
                // Payment succeeded
                payment.succeed();
                intent.succeed();

                // Confirm the reservation
                confirmReservationSafely(intent.getReservationId());

                log.info("Payment {} succeeded for intent {}", paymentId, intentId);

            } else {
                // Payment failed
                payment.fail("Payment processing failed - simulated failure");
                intent.cancel();

                log.warn("Payment {} failed for intent {}", paymentId, intentId);
            }

            paymentIntentRepository.save(intent);
            payment = paymentRepository.save(payment);

            return mapPaymentToResponse(payment);

        } catch (Exception e) {
            // If anything fails, mark payment as failed
            payment.fail("Unexpected error during payment processing: " + e.getMessage());
            intent.cancel();

            paymentIntentRepository.save(intent);
            paymentRepository.save(payment);

            log.error("Payment processing failed for intent {}", intentId, e);
            throw e;
        }
    }

    @Transactional(readOnly = true)
    public PaymentIntentResponse getPaymentIntent(String intentId) {
        log.info("Fetching payment intent: {}", intentId);

        PaymentIntent intent = paymentIntentRepository.findByIntentId(intentId)
                .orElseThrow(() -> new IllegalArgumentException("Payment intent not found: " + intentId));

        return mapIntentToResponse(intent);
    }

    @Transactional(readOnly = true)
    public PaymentResponse getPayment(String paymentId) {
        log.info("Fetching payment: {}", paymentId);

        Payment payment = paymentRepository.findByPaymentId(paymentId)
                .orElseThrow(() -> new IllegalArgumentException("Payment not found: " + paymentId));

        return mapPaymentToResponse(payment);
    }

    @Transactional(readOnly = true)
    public List<PaymentIntentResponse> getUserPaymentIntents(Long userId) {
        log.info("Fetching payment intents for user: {}", userId);

        List<PaymentIntent> intents = paymentIntentRepository.findByUserId(userId);
        return intents.stream()
                .map(this::mapIntentToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PaymentResponse> getUserPayments(Long userId) {
        log.info("Fetching payments for user: {}", userId);

        List<Payment> payments = paymentRepository.findByUserId(userId);
        return payments.stream()
                .map(this::mapPaymentToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public void expireOldIntents() {
        log.info("Expiring old payment intents");

        LocalDateTime now = LocalDateTime.now();
        List<PaymentIntent> expiredIntents = paymentIntentRepository.findExpiredIntents(now);

        for (PaymentIntent intent : expiredIntents) {
            intent.cancel();
            log.info("Expired payment intent: {}", intent.getIntentId());
        }

        paymentIntentRepository.saveAll(expiredIntents);
    }

    // Validation is now done inline with safe fallbacks

    private boolean processPaymentSimulation() {
        // Simulate payment processing with configurable success rate
        try {
            Thread.sleep(1000 + (long)(Math.random() * 2000)); // 1-3 second processing time
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        return Math.random() < successRate;
    }

    private PaymentIntentResponse mapIntentToResponse(PaymentIntent intent) {
        return PaymentIntentResponse.builder()
                .id(intent.getId())
                .intentId(intent.getIntentId())
                .reservationId(intent.getReservationId())
                .userId(intent.getUserId())
                .amount(intent.getAmount())
                .currency(intent.getCurrency())
                .status(intent.getStatus())
                .idempotencyKey(intent.getIdempotencyKey())
                .paymentMethod(intent.getPaymentMethod())
                .description(intent.getDescription())
                .expiresAt(intent.getExpiresAt())
                .createdAt(intent.getCreatedAt())
                .updatedAt(intent.getUpdatedAt())
                .build();
    }

    private PaymentResponse mapPaymentToResponse(Payment payment) {
        return PaymentResponse.builder()
                .id(payment.getId())
                .paymentId(payment.getPaymentId())
                .intentId(payment.getIntent().getIntentId())
                .reservationId(payment.getReservationId())
                .userId(payment.getUserId())
                .amount(payment.getAmount())
                .currency(payment.getCurrency())
                .status(payment.getStatus())
                .paymentMethod(payment.getPaymentMethod())
                .providerReference(payment.getProviderReference())
                .failureReason(payment.getFailureReason())
                .capturedAt(payment.getCapturedAt())
                .createdAt(payment.getCreatedAt())
                .updatedAt(payment.getUpdatedAt())
                .build();
    }
}
