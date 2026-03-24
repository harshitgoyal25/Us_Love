package com.couples.backend.service;

import com.couples.backend.model.User;
import com.couples.backend.repository.UserRepository;
import com.couples.backend.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.util.Map;

@Service
public class AuthService {

    private final UserRepository userRepo;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthService(UserRepository userRepo, PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userRepo = userRepo;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    public Map<String, String> register(String name, String email, String password) {
        if (userRepo.findByEmail(email).isPresent()) {
            throw new RuntimeException("Email already exists");
        }
        User user = new User();
        user.setName(name);
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(password));
        User saved = userRepo.save(user);
        String token = jwtUtil.generateToken(email);
        return Map.of("token", token, "name", name, "userId", saved.getId().toString());
    }

    public Map<String, String> login(String email, String password) {
        User user = userRepo.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw new RuntimeException("Wrong password");
        }
        String token = jwtUtil.generateToken(email);
        return Map.of(
            "token", token,
            "name", user.getName(),
            "userId", user.getId().toString()
        );
    }
}