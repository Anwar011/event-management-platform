package com.eventplatform.user.service;

import com.eventplatform.user.dto.*;
import com.eventplatform.user.entity.User;
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

        // TEMP: Skip JWT generation for testing
        return AuthResponse.builder()
                .token("temp-token-" + user.getId())
                .userId(user.getId())
                .email(user.getEmail())
                .roles(Set.of(user.getRole().name()))
                .build();
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        if (!"ACTIVE".equals(user.getStatus())) {
            throw new IllegalArgumentException("User account is not active");
        }

        Set<String> roles = Set.of(user.getRole().name());

        String token = jwtService.generateToken(user.getId(), user.getEmail(), roles);

        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .email(user.getEmail())
                .roles(roles)
                .build();
    }

    public UserResponse getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

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
}

