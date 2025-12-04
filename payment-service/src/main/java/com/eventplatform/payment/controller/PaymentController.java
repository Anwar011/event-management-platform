package com.eventplatform.payment.controller;

import com.eventplatform.payment.dto.CreatePaymentIntentRequest;
import com.eventplatform.payment.dto.PaymentIntentResponse;
import com.eventplatform.payment.dto.PaymentResponse;
import com.eventplatform.payment.service.PaymentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    // === Modern Payment Intent API ===

    @PostMapping("/intents")
    public ResponseEntity<PaymentIntentResponse> createPaymentIntent(
            @Valid @RequestBody CreatePaymentIntentRequest request) {
        log.info("Create payment intent request for reservation: {}", request.getReservationId());
        PaymentIntentResponse response = paymentService.createPaymentIntent(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/intents/{intentId}/capture")
    public ResponseEntity<PaymentResponse> capturePayment(
            @PathVariable String intentId,
            @RequestParam(required = false) String idempotencyKey) {
        log.info("Capture payment request for intent: {}", intentId);
        PaymentResponse response = paymentService.capturePayment(intentId, idempotencyKey);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/intents/{intentId}")
    public ResponseEntity<PaymentIntentResponse> getPaymentIntent(@PathVariable String intentId) {
        log.info("Get payment intent request for: {}", intentId);
        PaymentIntentResponse response = paymentService.getPaymentIntent(intentId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/intents/user/{userId}")
    public ResponseEntity<List<PaymentIntentResponse>> getUserPaymentIntents(@PathVariable Long userId) {
        log.info("Get payment intents request for user: {}", userId);
        List<PaymentIntentResponse> response = paymentService.getUserPaymentIntents(userId);
        return ResponseEntity.ok(response);
    }

    // === Legacy/Backward Compatible API ===

    @PostMapping
    public ResponseEntity<PaymentResponse> createPayment(@Valid @RequestBody CreatePaymentIntentRequest request) {
        log.info("Create payment (legacy) request for reservation: {}", request.getReservationId());
        // Create intent and immediately capture
        PaymentIntentResponse intent = paymentService.createPaymentIntent(request);
        PaymentResponse response = paymentService.capturePayment(intent.getIntentId(), null);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<PaymentResponse>> getAllPayments() {
        log.info("Get all payments request");
        List<PaymentResponse> response = paymentService.getAllPayments();
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{paymentId}")
    public ResponseEntity<PaymentResponse> getPayment(@PathVariable String paymentId) {
        log.info("Get payment request for: {}", paymentId);
        PaymentResponse response = paymentService.getPayment(paymentId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<PaymentResponse>> getUserPayments(@PathVariable Long userId) {
        log.info("Get payments request for user: {}", userId);
        List<PaymentResponse> response = paymentService.getUserPayments(userId);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{paymentId}/status")
    public ResponseEntity<PaymentResponse> updatePaymentStatus(
            @PathVariable String paymentId,
            @RequestBody java.util.Map<String, String> statusUpdate) {
        log.info("Update payment status request for: {}", paymentId);
        String status = statusUpdate.get("status");
        PaymentResponse response = paymentService.updatePaymentStatus(paymentId, status);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{paymentId}/process")
    public ResponseEntity<PaymentResponse> processPayment(
            @PathVariable String paymentId,
            @RequestBody(required = false) java.util.Map<String, Object> paymentDetails) {
        log.info("Process payment request for: {}", paymentId);
        // For backward compatibility, this is an alias for getting payment status
        PaymentResponse response = paymentService.getPayment(paymentId);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/cleanup")
    public ResponseEntity<Void> cleanupExpiredIntents() {
        log.info("Cleanup expired payment intents request");
        paymentService.expireOldIntents();
        return ResponseEntity.ok().build();
    }

    // Health check endpoint
    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        return ResponseEntity.ok("{\"service\":\"payment-service\",\"status\":\"ok\"}");
    }
}

