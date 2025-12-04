package com.eventplatform.reservation.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class ReservationResponse {

    private Long id;
    private String reservationId;
    private Long userId;
    private Long eventId;
    private Integer quantity;
    private BigDecimal totalPrice;
    private String status;
    private String idempotencyKey;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<ReservationItemResponse> items;
}



