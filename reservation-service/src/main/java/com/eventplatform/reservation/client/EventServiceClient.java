package com.eventplatform.reservation.client;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

@ConditionalOnProperty(name = "feature.event-integration", havingValue = "true", matchIfMissing = false)
@FeignClient(name = "event-service", url = "http://localhost:8082")
public interface EventServiceClient {

    @GetMapping("/events/{eventId}/availability")
    EventAvailabilityResponse getEventAvailability(@PathVariable Long eventId);

    @PostMapping("/events/{eventId}/reserve")
    ReservationResultResponse reserveCapacity(@PathVariable Long eventId, @RequestParam int quantity);

    @PostMapping("/events/{eventId}/release")
    void releaseCapacity(@PathVariable Long eventId, @RequestParam int quantity);

    @GetMapping("/events/{eventId}")
    EventResponse getEvent(@PathVariable Long eventId);

    // Response DTOs for Event Service communication
    record EventAvailabilityResponse(Long eventId, Integer availableCapacity) {}

    record ReservationResultResponse(Long eventId, Integer quantity, Boolean success, String message) {}

    record EventResponse(Long id, String title, String status, Integer capacity, BigDecimal price) {}
}
