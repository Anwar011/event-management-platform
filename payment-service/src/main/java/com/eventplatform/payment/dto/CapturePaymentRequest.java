package com.eventplatform.payment.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class CapturePaymentRequest {

    @Size(max = 255, message = "Idempotency key cannot exceed 255 characters")
    private String idempotencyKey;

    // Optional: additional capture parameters could go here
    private String paymentMethodDetails;
}





