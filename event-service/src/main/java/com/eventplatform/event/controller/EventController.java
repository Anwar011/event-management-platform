package com.eventplatform.event.controller;

import com.eventplatform.event.dto.CreateEventRequest;
import com.eventplatform.event.dto.EventResponse;
import com.eventplatform.event.dto.EventSearchRequest;
import com.eventplatform.event.dto.UpdateEventRequest;
import com.eventplatform.event.service.EventService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/events")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    @PostMapping
    public ResponseEntity<EventResponse> createEvent(@Valid @RequestBody CreateEventRequest request) {
        log.info("Create event request received");
        EventResponse response = eventService.createEvent(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{eventId}")
    public ResponseEntity<EventResponse> getEvent(@PathVariable Long eventId) {
        log.info("Get event request for ID: {}", eventId);
        EventResponse response = eventService.getEvent(eventId);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{eventId}")
    public ResponseEntity<EventResponse> updateEvent(
            @PathVariable Long eventId,
            @Valid @RequestBody UpdateEventRequest request) {
        log.info("Update event request for ID: {}", eventId);
        EventResponse response = eventService.updateEvent(eventId, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{eventId}")
    public ResponseEntity<Void> deleteEvent(@PathVariable Long eventId) {
        log.info("Delete event request for ID: {}", eventId);
        eventService.deleteEvent(eventId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{eventId}/publish")
    public ResponseEntity<EventResponse> publishEvent(@PathVariable Long eventId) {
        log.info("Publish event request for ID: {}", eventId);
        EventResponse response = eventService.publishEvent(eventId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/organizer/{organizerId}")
    public ResponseEntity<List<EventResponse>> getEventsByOrganizer(@PathVariable Long organizerId) {
        log.info("Get events by organizer request for ID: {}", organizerId);
        List<EventResponse> response = eventService.getEventsByOrganizer(organizerId);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    public ResponseEntity<Page<EventResponse>> searchEvents(EventSearchRequest request) {
        log.info("Search events request with filters");
        Page<EventResponse> response = eventService.searchEvents(request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{eventId}/availability")
    public ResponseEntity<EventAvailabilityResponse> getEventAvailability(@PathVariable Long eventId) {
        log.info("Get event availability request for ID: {}", eventId);
        Integer availableCapacity = eventService.getAvailableCapacity(eventId);
        EventAvailabilityResponse response = EventAvailabilityResponse.builder()
                .eventId(eventId)
                .availableCapacity(availableCapacity)
                .build();
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{eventId}/reserve")
    public ResponseEntity<ReservationResponse> reserveCapacity(
            @PathVariable Long eventId,
            @RequestParam int quantity) {
        log.info("Reserve capacity request for event {}: quantity {}", eventId, quantity);
        boolean success = eventService.reserveCapacity(eventId, quantity);
        ReservationResponse response = ReservationResponse.builder()
                .eventId(eventId)
                .quantity(quantity)
                .success(success)
                .message(success ? "Capacity reserved successfully" : "Insufficient capacity available")
                .build();
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{eventId}/release")
    public ResponseEntity<Void> releaseCapacity(
            @PathVariable Long eventId,
            @RequestParam int quantity) {
        log.info("Release capacity request for event {}: quantity {}", eventId, quantity);
        eventService.releaseCapacity(eventId, quantity);
        return ResponseEntity.ok().build();
    }

    // Helper response classes
    @lombok.Data
    @lombok.Builder
    public static class EventAvailabilityResponse {
        private Long eventId;
        private Integer availableCapacity;
    }

    @lombok.Data
    @lombok.Builder
    public static class ReservationResponse {
        private Long eventId;
        private Integer quantity;
        private Boolean success;
        private String message;
    }
}
