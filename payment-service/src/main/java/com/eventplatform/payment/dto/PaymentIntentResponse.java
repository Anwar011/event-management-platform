package com.eventplatform.payment.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class PaymentIntentResponse {

    private Long id;
    private String intentId;
    private String reservationId;
    private Long userId;
    private BigDecimal amount;
    private String currency;
    private String status;
    private String idempotencyKey;
    private String paymentMethod;
    private String description;
    private LocalDateTime expiresAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
