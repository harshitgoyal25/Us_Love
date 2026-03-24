package com.couples.backend.controller;

import com.couples.backend.dto.GameEvent;
import com.couples.backend.model.GameSession;
import com.couples.backend.repository.GameSessionRepository;
import com.couples.backend.service.RoomService;
import org.springframework.messaging.handler.annotation.*;
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
    public void handleEvent(@DestinationVariable String roomId, GameEvent event) {
        switch (event.getType()) {

            case "PARTNER_JOINED":
                messaging.convertAndSend("/topic/room/" + roomId,
                    Map.of("type", "PARTNER_JOINED"));
                break;

            case "GAME_SELECTED":
                roomService.setGame(roomId, event.getGame());
                messaging.convertAndSend("/topic/room/" + roomId,
                    Map.of("type", "GAME_START", "game", event.getGame()));
                break;

            case "GAME_ACTION":
                messaging.convertAndSend("/topic/room/" + roomId,
                    Map.of("type", "GAME_STATE_UPDATE", "payload", event.getPayload()));
                break;

            case "GAME_END":
                messaging.convertAndSend("/topic/room/" + roomId,
                    Map.of("type", "GAME_END", "payload", event.getPayload()));

                // Persist game session to Supabase
                Map<String, String> room = roomService.getRoom(roomId);
                if (room != null && room.containsKey("coupleId")) {
                    Map<String, Object> payload = event.getPayload();
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