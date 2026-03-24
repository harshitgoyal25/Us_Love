package com.couples.backend.repository;

import com.couples.backend.model.GameSession;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface GameSessionRepository extends JpaRepository<GameSession, UUID> {
}