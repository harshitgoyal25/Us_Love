package com.couples.backend.controller;

import com.couples.backend.dto.LoginRequest;
import com.couples.backend.dto.RegisterRequest;
import com.couples.backend.service.AuthService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest req) {
        return ResponseEntity.ok(authService.register(
            req.getName(), req.getEmail(), req.getPassword()
        ));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        return ResponseEntity.ok(authService.login(
            req.getEmail(), req.getPassword()
        ));
    }

    @GetMapping("/health")
public ResponseEntity<?> health() {
    return ResponseEntity.ok(Map.of("status", "ok"));
}
}