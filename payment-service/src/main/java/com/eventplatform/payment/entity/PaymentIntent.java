package com.eventplatform.payment.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "payment_intents")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentIntent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "intent_id", nullable = false, unique = true)
    private String intentId;

    @Column(name = "reservation_id", nullable = false)
    private String reservationId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal amount;

    @Column(nullable = false)
    @Builder.Default
    private String currency = "USD";

    @Column(nullable = false)
    @Builder.Default
    private String status = "CREATED";

    @Column(name = "idempotency_key", unique = true)
    private String idempotencyKey;

    @Column(name = "payment_method")
    @Builder.Default
    private String paymentMethod = "CARD";

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public enum Status {
        CREATED,
        REQUIRES_PAYMENT_METHOD,
        SUCCEEDED,
        CANCELED,
        PROCESSING,
        REQUIRES_ACTION,
        REQUIRES_CONFIRMATION
    }

    // Helper methods
    public boolean isCreated() {
        return "CREATED".equals(status);
    }

    public boolean isSucceeded() {
        return "SUCCEEDED".equals(status);
    }

    public boolean isCanceled() {
        return "CANCELED".equals(status);
    }

    public boolean isExpired() {
        return expiresAt != null && LocalDateTime.now().isAfter(expiresAt);
    }

    public void succeed() {
        this.status = "SUCCEEDED";
    }

    public void cancel() {
        this.status = "CANCELED";
    }

    public void requirePaymentMethod() {
        this.status = "REQUIRES_PAYMENT_METHOD";
    }
}





