package com.eventplatform.event.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class UpdateEventRequest {

    @Size(min = 3, max = 255, message = "Title must be between 3 and 255 characters")
    private String title;

    @Size(max = 2000, message = "Description cannot exceed 2000 characters")
    private String description;

    private String eventType;
    private String venue;

    @Size(max = 500, message = "Address cannot exceed 500 characters")
    private String address;

    private String city;
    private String state;
    private String country;
    private String postalCode;

    @Future(message = "Start date must be in the future")
    private LocalDateTime startDate;

    private LocalDateTime endDate;

    @Min(value = 1, message = "Capacity must be at least 1")
    @Max(value = 100000, message = "Capacity cannot exceed 100,000")
    private Integer capacity;

    @DecimalMin(value = "0.00", message = "Price cannot be negative")
    @DecimalMax(value = "10000.00", message = "Price cannot exceed 10,000")
    private BigDecimal price;

    private String status;
}
