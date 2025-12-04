package com.eventplatform.user.service;

import com.eventplatform.user.dto.*;
import com.eventplatform.user.entity.User;
import com.eventplatform.user.exception.GlobalExceptionHandler;
import com.eventplatform.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already exists");
        }

        User user = new User();
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setStatus("ACTIVE");
        user.setRole(User.Role.ROLE_USER);
        user = userRepository.save(user);

        Set<String> roles = Set.of(user.getRole().name());

        // TEMP: Use simple token for stability
        String token = "jwt-token-" + user.getId() + "-" + System.currentTimeMillis();

        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .roles(roles)
                .build();
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new com.eventplatform.user.exception.GlobalExceptionHandler.UnauthorizedException(
                        "Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new com.eventplatform.user.exception.GlobalExceptionHandler.UnauthorizedException(
                    "Invalid email or password");
        }

        if (!"ACTIVE".equals(user.getStatus())) {
            throw new IllegalArgumentException("User account is not active");
        }

        Set<String> roles = Set.of(user.getRole().name());

        // TEMP: Use simple token to test service stability
        String token = "jwt-token-" + user.getId() + "-" + System.currentTimeMillis();

        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .roles(roles)
                .build();
    }

    public UserResponse getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(
                        () -> new GlobalExceptionHandler.ResourceNotFoundException("User not found with id: " + id));

        Set<String> roles = Set.of(user.getRole().name());

        return UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .status(user.getStatus())
                .roles(roles)
                .build();
    }

    public UserResponse getCurrentUser(Long userId) {
        return getUserById(userId);
    }

    @Transactional(readOnly = true)
    public java.util.List<UserResponse> getAllUsers() {
        return userRepository.findAll().stream()
                .map(user -> UserResponse.builder()
                        .id(user.getId())
                        .email(user.getEmail())
                        .firstName(user.getFirstName())
                        .lastName(user.getLastName())
                        .status(user.getStatus())
                        .roles(Set.of(user.getRole().name()))
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional
    public UserResponse updateUser(Long id, UpdateUserRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(
                        () -> new GlobalExceptionHandler.ResourceNotFoundException("User not found with id: " + id));

        if (request.getEmail() != null && !request.getEmail().equals(user.getEmail())) {
            if (userRepository.existsByEmail(request.getEmail())) {
                throw new IllegalArgumentException("Email already exists");
            }
            user.setEmail(request.getEmail());
        }

        if (request.getFirstName() != null) {
            user.setFirstName(request.getFirstName());
        }
        if (request.getLastName() != null) {
            user.setLastName(request.getLastName());
        }
        if (request.getStatus() != null) {
            user.setStatus(request.getStatus());
        }

        user = userRepository.save(user);
        return getUserById(user.getId());
    }

    @Transactional
    public void deleteUser(Long id) {
        // Make DELETE idempotent - if user doesn't exist, just return success
        if (!userRepository.existsById(id)) {
            log.info("User {} already deleted or doesn't exist", id);
            return;
        }
        userRepository.deleteById(id);
    }
}
