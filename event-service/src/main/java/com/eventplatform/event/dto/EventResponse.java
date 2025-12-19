package com.eventplatform.event.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class EventResponse {

    private Long id;
    private String title;
    private String description;
    private String eventType;
    private String venue;
    private String address;
    private String city;
    private String state;
    private String country;
    private String postalCode;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private Integer capacity;
    private BigDecimal price;
    private Long organizerId;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Additional computed fields
    private Integer availableCapacity;
    private Integer reservedCapacity;
}





