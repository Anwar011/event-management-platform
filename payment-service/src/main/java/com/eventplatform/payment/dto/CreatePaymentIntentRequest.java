package com.eventplatform.payment.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class CreatePaymentIntentRequest {

    @NotBlank(message = "Reservation ID is required")
    private String reservationId;

    @NotNull(message = "User ID is required")
    private Long userId;

    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0.01", message = "Amount must be at least 0.01")
    @DecimalMax(value = "10000.00", message = "Amount cannot exceed 10,000")
    private BigDecimal amount;

    private String currency = "USD";

    private String paymentMethod = "CARD";

    private String description;

    @Size(max = 255, message = "Idempotency key cannot exceed 255 characters")
    private String idempotencyKey;
}



