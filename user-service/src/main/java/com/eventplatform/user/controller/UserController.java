package com.eventplatform.user.controller;

import com.eventplatform.user.dto.UserResponse;
import com.eventplatform.user.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/ping")
    public ResponseEntity<Map<String, String>> ping() {
        return ResponseEntity.ok(Map.of("service", "user-service", "status", "ok"));
    }

    @GetMapping("/me")
    public ResponseEntity<UserResponse> getCurrentUser(@RequestHeader("X-User-Id") Long userId) {
        log.info("Get current user request for userId: {}", userId);
        UserResponse response = userService.getCurrentUser(userId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUserById(@PathVariable Long id) {
        log.info("Get user request for userId: {}", id);
        UserResponse response = userService.getUserById(id);
        return ResponseEntity.ok(response);
    }
}

