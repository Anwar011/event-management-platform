package com.eventplatform.payment.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

@FeignClient(name = "reservation-service", url = "http://localhost:8083")
public interface ReservationServiceClient {

    @GetMapping("/reservations/{reservationId}")
    ReservationResponse getReservation(@PathVariable String reservationId);

    @PostMapping("/reservations/{reservationId}/confirm")
    ReservationResponse confirmReservation(@PathVariable String reservationId);

    // Response DTOs for Reservation Service communication
    record ReservationResponse(
            Long id,
            String reservationId,
            Long userId,
            Long eventId,
            Integer quantity,
            java.math.BigDecimal totalPrice,
            String status,
            String idempotencyKey,
            java.time.LocalDateTime createdAt,
            java.time.LocalDateTime updatedAt
    ) {}
}
