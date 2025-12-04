package com.eventplatform.payment.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class PaymentResponse {

    private Long id;
    private String paymentId;
    private String intentId;
    private String reservationId;
    private Long userId;
    private BigDecimal amount;
    private String currency;
    private String status;
    private String paymentMethod;
    private String providerReference;
    private String failureReason;
    private LocalDateTime capturedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}



