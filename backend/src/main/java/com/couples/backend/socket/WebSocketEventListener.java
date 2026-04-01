package com.couples.backend.socket;

import com.couples.backend.service.RoomService;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;
import java.util.Map;

@Component
public class WebSocketEventListener {

    private final RoomService roomService;
    private final SimpMessagingTemplate messaging;

    public WebSocketEventListener(RoomService roomService, SimpMessagingTemplate messaging) {
        this.roomService = roomService;
        this.messaging = messaging;
    }

    @EventListener
    public void handleWebSocketDisconnectListener(SessionDisconnectEvent event) {
        String sessionId = event.getSessionId();
        String[] info = roomService.untrackSession(sessionId);
        
        if (info != null) {
            String roomId = info[0];
            String userId = info[1];
            
            System.out.println("User disconnected abruptly: " + userId + " from room: " + roomId);
            
            roomService.handleUserLeft(roomId, userId);
            
            // Broadcast the update so the remaining player sees the status change
            messaging.convertAndSend("/topic/room/" + roomId,
                Map.of("type", "PARTNER_LEFT"));
                
            Map<String, String> updatedRoom = roomService.getRoom(roomId);
            if (updatedRoom != null) {
                messaging.convertAndSend("/topic/room/" + roomId,
                    Map.of(
                        "type", "ROOM_UPDATE",
                        "hostId", updatedRoom.get("hostId"),
                        "code", updatedRoom.get("code"),
                        "hostName", updatedRoom.getOrDefault("hostName", "Player"),
                        "guestName", updatedRoom.getOrDefault("guestName", "")
                    ));
            }
        }
    }
}
