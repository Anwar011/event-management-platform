package com.eventplatform.reservation.controller;

import com.eventplatform.reservation.dto.CreateReservationRequest;
import com.eventplatform.reservation.dto.ReservationResponse;
import com.eventplatform.reservation.service.ReservationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/reservations")
@RequiredArgsConstructor
public class ReservationController {

    private final ReservationService reservationService;

    @PostMapping
    public ResponseEntity<ReservationResponse> createReservation(@Valid @RequestBody CreateReservationRequest request) {
        log.info("Create reservation request received for user {} event {}", request.getUserId(), request.getEventId());
        ReservationResponse response = reservationService.createReservation(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{reservationId}")
    public ResponseEntity<ReservationResponse> getReservation(@PathVariable String reservationId) {
        log.info("Get reservation request for: {}", reservationId);
        ReservationResponse response = reservationService.getReservation(reservationId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<ReservationResponse>> getUserReservations(@PathVariable Long userId) {
        log.info("Get reservations request for user: {}", userId);
        List<ReservationResponse> response = reservationService.getUserReservations(userId);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{reservationId}/confirm")
    public ResponseEntity<ReservationResponse> confirmReservation(@PathVariable String reservationId) {
        log.info("Confirm reservation request for: {}", reservationId);
        ReservationResponse response = reservationService.confirmReservation(reservationId);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{reservationId}/cancel")
    public ResponseEntity<ReservationResponse> cancelReservation(@PathVariable String reservationId) {
        log.info("Cancel reservation request for: {}", reservationId);
        ReservationResponse response = reservationService.cancelReservation(reservationId);
        return ResponseEntity.ok(response);
    }

    // Health check endpoint
    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        return ResponseEntity.ok("{\"service\":\"reservation-service\",\"status\":\"ok\"}");
    }
}
