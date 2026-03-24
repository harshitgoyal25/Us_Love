package com.couples.backend.repository;

import com.couples.backend.model.Couple;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface CoupleRepository extends JpaRepository<Couple, UUID> {
}