package com.eventplatform.event.service;

import com.eventplatform.event.dto.CreateEventRequest;
import com.eventplatform.event.dto.EventResponse;
import com.eventplatform.event.dto.EventSearchRequest;
import com.eventplatform.event.dto.UpdateEventRequest;
import com.eventplatform.event.entity.Event;
import com.eventplatform.event.entity.EventCapacity;
import com.eventplatform.event.exception.GlobalExceptionHandler.ResourceNotFoundException;
import com.eventplatform.event.repository.EventCapacityRepository;
import com.eventplatform.event.repository.EventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class EventService {

    private final EventRepository eventRepository;
    private final EventCapacityRepository eventCapacityRepository;

    @Transactional
    public EventResponse createEvent(CreateEventRequest request) {
        log.info("Creating event: {} by organizer: {}", request.getTitle(), request.getOrganizerId());

        // Validate that start date is in the future
        if (request.getStartDate().isBefore(java.time.LocalDateTime.now())) {
            throw new IllegalArgumentException("Event start date must be in the future");
        }

        // Create event entity
        Event event = Event.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .eventType(request.getEventType())
                .venue(request.getVenue())
                .address(request.getAddress())
                .city(request.getCity())
                .state(request.getState())
                .country(request.getCountry())
                .postalCode(request.getPostalCode())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .capacity(request.getCapacity())
                .price(request.getPrice())
                .organizerId(request.getOrganizerId())
                .status("DRAFT")
                .build();

        event = eventRepository.save(event);

        // Create capacity tracking
        EventCapacity capacity = EventCapacity.builder()
                .eventId(event.getId())
                .totalCapacity(request.getCapacity())
                .reservedCapacity(0)
                .availableCapacity(request.getCapacity()) // Initialize available capacity
                .build();

        eventCapacityRepository.save(capacity);

        log.info("Created event with ID: {} and capacity tracking", event.getId());
        return mapToResponse(event, capacity);
    }

    @Transactional(readOnly = true)
    public EventResponse getEvent(Long eventId) {
        log.info("Fetching event: {}", eventId);

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found: " + eventId));

        EventCapacity capacity = eventCapacityRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event capacity not found: " + eventId));

        return mapToResponse(event, capacity);
    }

    @Transactional
    public EventResponse updateEvent(Long eventId, UpdateEventRequest request) {
        log.info("Updating event: {}", eventId);

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found: " + eventId));

        // Only allow updates if event is not completed or cancelled
        if ("COMPLETED".equals(event.getStatus()) || "CANCELLED".equals(event.getStatus())) {
            throw new IllegalStateException("Cannot update completed or cancelled events");
        }

        // Update fields if provided
        if (request.getTitle() != null)
            event.setTitle(request.getTitle());
        if (request.getDescription() != null)
            event.setDescription(request.getDescription());
        if (request.getEventType() != null)
            event.setEventType(request.getEventType());
        if (request.getVenue() != null)
            event.setVenue(request.getVenue());
        if (request.getAddress() != null)
            event.setAddress(request.getAddress());
        if (request.getCity() != null)
            event.setCity(request.getCity());
        if (request.getState() != null)
            event.setState(request.getState());
        if (request.getCountry() != null)
            event.setCountry(request.getCountry());
        if (request.getPostalCode() != null)
            event.setPostalCode(request.getPostalCode());
        if (request.getStartDate() != null)
            event.setStartDate(request.getStartDate());
        if (request.getEndDate() != null)
            event.setEndDate(request.getEndDate());

        // Handle capacity updates carefully
        if (request.getCapacity() != null) {
            EventCapacity capacity = eventCapacityRepository.findById(eventId)
                    .orElseThrow(() -> new ResourceNotFoundException("Event capacity not found: " + eventId));

            if (request.getCapacity() < capacity.getReservedCapacity()) {
                throw new IllegalArgumentException("Cannot reduce capacity below reserved amount");
            }

            capacity.setTotalCapacity(request.getCapacity());
            eventCapacityRepository.save(capacity);
            event.setCapacity(request.getCapacity());
        }

        if (request.getPrice() != null)
            event.setPrice(request.getPrice());
        if (request.getStatus() != null)
            event.setStatus(request.getStatus());

        event = eventRepository.save(event);
        EventCapacity capacity = eventCapacityRepository.findById(eventId).orElse(null);

        log.info("Updated event: {}", eventId);
        return mapToResponse(event, capacity);
    }

    @Transactional
    public void deleteEvent(Long eventId) {
        log.info("Deleting event: {}", eventId);

        // Make DELETE idempotent - if event doesn't exist, just return success
        Event event = eventRepository.findById(eventId).orElse(null);
        if (event == null) {
            log.info("Event {} already deleted or doesn't exist", eventId);
            return;
        }

        // Only allow deletion of draft events
        if (!"DRAFT".equals(event.getStatus())) {
            throw new IllegalStateException("Can only delete draft events");
        }

        eventRepository.delete(event);
        log.info("Deleted event: {}", eventId);
    }

    @Transactional
    public EventResponse publishEvent(Long eventId) {
        log.info("Publishing event: {}", eventId);

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found: " + eventId));

        if (!"DRAFT".equals(event.getStatus())) {
            throw new IllegalStateException("Only draft events can be published");
        }

        event.setStatus("PUBLISHED");
        event = eventRepository.save(event);

        EventCapacity capacity = eventCapacityRepository.findById(eventId).orElse(null);
        log.info("Published event: {}", eventId);

        return mapToResponse(event, capacity);
    }

    @Transactional(readOnly = true)
    public List<EventResponse> getEventsByOrganizer(Long organizerId) {
        log.info("Fetching events for organizer: {}", organizerId);

        List<Event> events = eventRepository.findByOrganizerId(organizerId);
        return events.stream()
                .map(event -> {
                    EventCapacity capacity = eventCapacityRepository.findById(event.getId()).orElse(null);
                    return mapToResponse(event, capacity);
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<EventResponse> searchEvents(EventSearchRequest request) {
        log.info("Searching events with filters: {}", request);

        String status = request.getStatus() != null ? request.getStatus() : "PUBLISHED";
        Pageable pageable = PageRequest.of(request.getPage(), request.getSize(),
                Sort.by(Sort.Direction.ASC, "startDate"));

        // Use simple query - filter by status first, then apply other filters in memory
        // if needed
        // For now, just return published events with pagination
        Page<Event> eventsPage = eventRepository.findByStatusOrderByStartDateAsc(status, pageable);

        // Apply additional filters if provided (simple in-memory filtering for now)
        List<Event> filteredEvents = eventsPage.getContent().stream()
                .filter(event -> {
                    if (request.getCity() != null && !request.getCity().isEmpty() &&
                            !event.getCity().equalsIgnoreCase(request.getCity())) {
                        return false;
                    }
                    if (request.getEventType() != null && !request.getEventType().isEmpty() &&
                            !event.getEventType().equalsIgnoreCase(request.getEventType())) {
                        return false;
                    }
                    if (request.getSearchTerm() != null && !request.getSearchTerm().isEmpty()) {
                        String searchLower = request.getSearchTerm().toLowerCase();
                        if (!event.getTitle().toLowerCase().contains(searchLower) &&
                                (event.getDescription() == null
                                        || !event.getDescription().toLowerCase().contains(searchLower))) {
                            return false;
                        }
                    }
                    if (request.getStartDate() != null && event.getStartDate().isBefore(request.getStartDate())) {
                        return false;
                    }
                    if (request.getEndDate() != null && event.getEndDate() != null &&
                            event.getEndDate().isAfter(request.getEndDate())) {
                        return false;
                    }
                    return true;
                })
                .collect(Collectors.toList());

        // Create a new page with filtered results
        int start = (int) pageable.getOffset();
        int end = Math.min((start + pageable.getPageSize()), filteredEvents.size());
        List<Event> pagedEvents = filteredEvents.subList(Math.min(start, filteredEvents.size()), end);

        Page<Event> resultPage = new PageImpl<>(pagedEvents, pageable, filteredEvents.size());

        return resultPage.map(event -> {
            EventCapacity capacity = eventCapacityRepository.findById(event.getId()).orElse(null);
            return mapToResponse(event, capacity);
        });
    }

    @Transactional(readOnly = true)
    public Integer getAvailableCapacity(Long eventId) {
        return eventCapacityRepository.getAvailableCapacity(eventId);
    }

    @Transactional
    public boolean reserveCapacity(Long eventId, int quantity) {
        log.info("Reserving capacity for event {}: quantity {}", eventId, quantity);

        EventCapacity capacity = eventCapacityRepository.findByEventIdWithLock(eventId);
        if (capacity == null) {
            throw new ResourceNotFoundException("Event capacity not found: " + eventId);
        }

        boolean success = capacity.reserveCapacity(quantity);
        if (success) {
            eventCapacityRepository.save(capacity);
            log.info("Reserved {} capacity for event {}", quantity, eventId);
        } else {
            log.warn("Failed to reserve {} capacity for event {} (insufficient capacity)", quantity, eventId);
        }

        return success;
    }

    @Transactional
    public void releaseCapacity(Long eventId, int quantity) {
        log.info("Releasing capacity for event {}: quantity {}", eventId, quantity);

        EventCapacity capacity = eventCapacityRepository.findById(eventId).orElse(null);
        if (capacity != null) {
            capacity.releaseCapacity(quantity);
            eventCapacityRepository.save(capacity);
            log.info("Released {} capacity for event {}", quantity, eventId);
        }
    }

    private EventResponse mapToResponse(Event event, EventCapacity capacity) {
        return EventResponse.builder()
                .id(event.getId())
                .title(event.getTitle())
                .description(event.getDescription())
                .eventType(event.getEventType())
                .venue(event.getVenue())
                .address(event.getAddress())
                .city(event.getCity())
                .state(event.getState())
                .country(event.getCountry())
                .postalCode(event.getPostalCode())
                .startDate(event.getStartDate())
                .endDate(event.getEndDate())
                .capacity(event.getCapacity())
                .price(event.getPrice())
                .organizerId(event.getOrganizerId())
                .status(event.getStatus())
                .createdAt(event.getCreatedAt())
                .updatedAt(event.getUpdatedAt())
                .availableCapacity(capacity != null ? capacity.getAvailableCapacity() : event.getCapacity())
                .reservedCapacity(capacity != null ? capacity.getReservedCapacity() : 0)
                .build();
    }
}
