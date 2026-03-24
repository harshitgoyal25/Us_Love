package com.couples.backend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "couples")
public class Couple {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private UUID partnerAId;
    private UUID partnerBId;
    private LocalDateTime linkedAt;

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getPartnerAId() { return partnerAId; }
    public void setPartnerAId(UUID partnerAId) { this.partnerAId = partnerAId; }
    public UUID getPartnerBId() { return partnerBId; }
    public void setPartnerBId(UUID partnerBId) { this.partnerBId = partnerBId; }
    public LocalDateTime getLinkedAt() { return linkedAt; }
    public void setLinkedAt(LocalDateTime linkedAt) { this.linkedAt = linkedAt; }
}