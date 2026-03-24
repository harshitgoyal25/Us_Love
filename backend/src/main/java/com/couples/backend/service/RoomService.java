package com.couples.backend.service;

import com.couples.backend.dto.RoomResponse;
import com.couples.backend.model.Couple;
import com.couples.backend.repository.CoupleRepository;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class RoomService {

    private final CoupleRepository coupleRepository;
    private final Map<String, Map<String, String>> rooms = new ConcurrentHashMap<>();
    private final Map<String, String> codeToRoom = new ConcurrentHashMap<>();

    public RoomService(CoupleRepository coupleRepository) {
        this.coupleRepository = coupleRepository;
    }

    public RoomResponse createRoom(String userId) {
        String roomId = UUID.randomUUID().toString().substring(0, 8);
        String code = generateCode();
        Map<String, String> room = new HashMap<>();
        room.put("hostId", userId);
        room.put("code", code);
        room.put("game", "");
        rooms.put(roomId, room);
        codeToRoom.put(code, roomId);
        return new RoomResponse(roomId, code, "HOST");
    }

    public RoomResponse joinRoom(String code, String userId) {
        String roomId = codeToRoom.get(code.toUpperCase());
        if (roomId == null) throw new RuntimeException("Room not found");
        Map<String, String> room = rooms.get(roomId);
        room.put("guestId", userId);

        // Persist couple link to Supabase
        String hostId = room.get("hostId");
        Couple couple = new Couple();
        couple.setPartnerAId(UUID.fromString(hostId));
        couple.setPartnerBId(UUID.fromString(userId));
        couple.setLinkedAt(LocalDateTime.now());
        Couple saved = coupleRepository.save(couple);
        room.put("coupleId", saved.getId().toString());

        return new RoomResponse(roomId, code, "GUEST");
    }

    public void setGame(String roomId, String game) {
        if (rooms.containsKey(roomId)) {
            rooms.get(roomId).put("game", game);
        }
    }

    public Map<String, String> getRoom(String roomId) {
        return rooms.get(roomId);
    }

    private String generateCode() {
        String chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        StringBuilder sb = new StringBuilder();
        Random rnd = new Random();
        for (int i = 0; i < 6; i++) {
            sb.append(chars.charAt(rnd.nextInt(chars.length())));
        }
        return sb.toString();
    }
}