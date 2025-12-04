package com.eventplatform.reservation.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class ReservationItemResponse {

    private Long id;
    private String ticketType;
    private Integer quantity;
    private BigDecimal unitPrice;
    private LocalDateTime createdAt;
}



