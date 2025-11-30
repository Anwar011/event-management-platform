package com.eventplatform.event.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class EventSearchRequest {

    private String searchTerm;
    private String city;
    private String eventType;
    private String status;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private Integer page = 0;
    private Integer size = 20;
    private String sortBy = "startDate";
    private String sortDirection = "ASC";
}
