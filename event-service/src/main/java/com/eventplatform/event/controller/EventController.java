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
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/events")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        log.info("Event Service ping endpoint called");
        return ResponseEntity.ok("Event Service is running");
    }

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
        return ResponseEntity.ok().build();
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
    public ResponseEntity<Page<EventResponse>> searchEvents(
            @RequestParam(required = false) String searchTerm,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String eventType,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "startDate") String sortBy,
            @RequestParam(defaultValue = "ASC") String sortDirection) {

        EventSearchRequest request = new EventSearchRequest();
        request.setSearchTerm(searchTerm);
        request.setCity(city);
        request.setEventType(eventType);
        request.setStatus(status);
        request.setStartDate(startDate);
        request.setEndDate(endDate);
        request.setPage(page);
        request.setSize(size);
        request.setSortBy(sortBy);
        request.setSortDirection(sortDirection);

        log.info("Search events request with filters: {}", request);
        Page<EventResponse> response = eventService.searchEvents(request);
        return ResponseEntity.ok(response);
    }

    // Dedicated search endpoint for backward compatibility (keyword parameter)
    @GetMapping("/search")
    public ResponseEntity<Page<EventResponse>> searchEventsByKeyword(
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(required = false) String searchTerm,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String eventType,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "startDate") String sortBy,
            @RequestParam(defaultValue = "ASC") String sortDirection) {

        EventSearchRequest request = new EventSearchRequest();
        // Use keyword if provided, otherwise use searchTerm
        request.setSearchTerm(keyword != null ? keyword : searchTerm);
        request.setCity(city);
        request.setEventType(eventType);
        request.setStatus(status);
        request.setStartDate(startDate);
        request.setEndDate(endDate);
        request.setPage(page);
        request.setSize(size);
        request.setSortBy(sortBy);
        request.setSortDirection(sortDirection);

        log.info("Search events request (keyword API) with filters: {}", request);
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
