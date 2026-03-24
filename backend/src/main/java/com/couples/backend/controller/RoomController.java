package com.couples.backend.controller;

import com.couples.backend.dto.RoomResponse;
import com.couples.backend.service.RoomService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/rooms")
@CrossOrigin(origins = "*")
public class RoomController {

    private final RoomService roomService;

    public RoomController(RoomService roomService) {
        this.roomService = roomService;
    }

    @PostMapping("/create")
    public ResponseEntity<?> create(@RequestHeader("X-User-Id") String userId) {
        return ResponseEntity.ok(roomService.createRoom(userId));
    }

    @PostMapping("/join")
    public ResponseEntity<?> join(@RequestBody Map<String, String> body,
                                   @RequestHeader("X-User-Id") String userId) {
        return ResponseEntity.ok(roomService.joinRoom(body.get("code"), userId));
    }
}