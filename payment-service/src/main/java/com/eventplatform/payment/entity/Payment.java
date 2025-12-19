package com.eventplatform.payment.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "payments")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "payment_id", nullable = false, unique = true)
    private String paymentId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "intent_id", nullable = false)
    private PaymentIntent intent;

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
    private String status = "PENDING";

    @Column(name = "payment_method")
    @Builder.Default
    private String paymentMethod = "CARD";

    @Column(name = "provider_reference")
    private String providerReference;

    @Column(name = "failure_reason", columnDefinition = "TEXT")
    private String failureReason;

    @Column(name = "captured_at")
    private LocalDateTime capturedAt;

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
        PENDING,
        PROCESSING,
        SUCCEEDED,
        FAILED,
        CANCELED,
        REQUIRES_ACTION
    }

    // Helper methods
    public boolean isPending() {
        return "PENDING".equals(status);
    }

    public boolean isSucceeded() {
        return "SUCCEEDED".equals(status);
    }

    public boolean isFailed() {
        return "FAILED".equals(status);
    }

    public void succeed() {
        this.status = "SUCCEEDED";
        this.capturedAt = LocalDateTime.now();
    }

    public void fail(String reason) {
        this.status = "FAILED";
        this.failureReason = reason;
    }

    public void cancel() {
        this.status = "CANCELED";
    }

    public void setProcessing() {
        this.status = "PROCESSING";
    }
}





