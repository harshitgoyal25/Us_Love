package com.couples.backend.controller;

import com.couples.backend.dto.GameEvent;
import com.couples.backend.model.GameSession;
import com.couples.backend.repository.GameSessionRepository;
import com.couples.backend.service.RoomService;
import org.springframework.messaging.handler.annotation.*;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@Controller
public class GameSocketController {

    private final SimpMessagingTemplate messaging;
    private final RoomService roomService;
    private final GameSessionRepository gameSessionRepository;

    public GameSocketController(SimpMessagingTemplate messaging, RoomService roomService,
                                GameSessionRepository gameSessionRepository) {
        this.messaging = messaging;
        this.roomService = roomService;
        this.gameSessionRepository = gameSessionRepository;
    }

    @MessageMapping("/room/{roomId}")
    public void handleEvent(@DestinationVariable String roomId, GameEvent event,
                            SimpMessageHeaderAccessor headerAccessor) {
        String sessionId = headerAccessor.getSessionId();
        Map<String, Object> payload = event.getPayload();

        if (payload != null && payload.containsKey("userId")) {
            roomService.trackSession(sessionId, roomId, (String) payload.get("userId"));
        }
        
        switch (event.getType()) {

            case "PARTNER_JOINED": {
                if (payload != null && payload.get("userId") instanceof String) {
                    roomService.syncParticipantName(roomId, (String) payload.get("userId"));
                }
                messaging.convertAndSend("/topic/room/" + roomId,
                    Map.of(
                        "type", "PARTNER_JOINED",
                        "hostName", roomService.getHostName(roomId),
                        "guestName", roomService.getGuestName(roomId)
                    ));
                break;
            }

            case "LOBBY_SYNC": {
                messaging.convertAndSend("/topic/room/" + roomId,
                    Map.of(
                        "type", "GAME_STATE_UPDATE",
                        "payload", payload != null ? payload : Map.of("action", "LOBBY_SYNC")
                    ));
                break;
            }

            case "GAME_SELECTED":
                roomService.setGame(roomId, event.getGame());
                messaging.convertAndSend("/topic/room/" + roomId,
                    Map.of("type", "GAME_START", "game", event.getGame()));
                break;

            case "GAME_ACTION": {
                if (payload != null && "PARTNER_LEFT".equals(payload.get("action"))) {
                    String senderId = (String) payload.get("userId");
                    if (senderId != null) {
                        roomService.handleUserLeft(roomId, senderId);
                        
                        // Broadcast explicit PARTNER_LEFT to the remaining player
                        messaging.convertAndSend("/topic/room/" + roomId,
                            Map.of("type", "PARTNER_LEFT"));
                        
                        // Broadcast updated room state
                        Map<String, String> updatedRoom = roomService.getRoom(roomId);
                        if (updatedRoom != null) {
                            String currentHostId = updatedRoom.get("hostId");
                            messaging.convertAndSend("/topic/room/" + roomId,
                                Map.of(
                                    "type", "ROOM_UPDATE",
                                    "hostId", currentHostId,
                                    "code", updatedRoom.get("code"),
                                    "hostName", updatedRoom.getOrDefault("hostName", "Player"),
                                    "guestName", updatedRoom.getOrDefault("guestName", "")
                                ));
                        }
                    }
                }
                // Also broadcast the full state update for game compatibility
                messaging.convertAndSend("/topic/room/" + roomId,
                    Map.of("type", "GAME_STATE_UPDATE", "payload", event.getPayload()));
                break;
            }

            case "BACK_TO_LOBBY": {
                messaging.convertAndSend("/topic/room/" + roomId,
                    Map.of(
                        "type", "GAME_STATE_UPDATE",
                        "payload", Map.of("action", "BACK_TO_LOBBY")
                    ));
                break;
            }

            case "GAME_END": {
                messaging.convertAndSend("/topic/room/" + roomId,
                    Map.of("type", "GAME_END", "payload", event.getPayload()));

                // Persist game session to Supabase
                Map<String, String> room = roomService.getRoom(roomId);
                if (room != null && room.containsKey("coupleId")) {
                    GameSession session = new GameSession();
                    session.setCoupleId(UUID.fromString(room.get("coupleId")));
                    session.setGameType(room.get("game"));
                    session.setPlayedAt(LocalDateTime.now());
                    if (payload != null) {
                        if (payload.get("scoreA") instanceof Integer)
                            session.setScoreA((Integer) payload.get("scoreA"));
                        if (payload.get("scoreB") instanceof Integer)
                            session.setScoreB((Integer) payload.get("scoreB"));
                        if (payload.get("winnerId") instanceof String)
                            session.setWinnerId(UUID.fromString((String) payload.get("winnerId")));
                    }
                    gameSessionRepository.save(session);
                }
                break;
            }
        }
    }
}