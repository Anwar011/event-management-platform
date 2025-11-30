package com.eventplatform.reservation.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.List;

@Data
public class CreateReservationRequest {

    @NotNull(message = "User ID is required")
    private Long userId;

    @NotNull(message = "Event ID is required")
    private Long eventId;

    @NotNull(message = "Quantity is required")
    @Min(value = 1, message = "Quantity must be at least 1")
    @Max(value = 4, message = "Cannot reserve more than 4 tickets per user per event")
    private Integer quantity;

    @Size(max = 255, message = "Idempotency key cannot exceed 255 characters")
    private String idempotencyKey;

    // Optional: specific ticket types (for future extensibility)
    private List<ReservationItemRequest> items;
}
