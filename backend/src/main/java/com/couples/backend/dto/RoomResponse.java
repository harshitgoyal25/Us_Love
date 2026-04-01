package com.couples.backend.dto;

public class RoomResponse {
    private String roomId;
    private String code;
    private String role;
    private String hostName;
    private String guestName;

    public RoomResponse(String roomId, String code, String role, String hostName, String guestName) {
        this.roomId = roomId;
        this.code = code;
        this.role = role;
        this.hostName = hostName;
        this.guestName = guestName;
    }

    public String getRoomId() { return roomId; }
    public void setRoomId(String roomId) { this.roomId = roomId; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public String getHostName() { return hostName; }
    public void setHostName(String hostName) { this.hostName = hostName; }
    public String getGuestName() { return guestName; }
    public void setGuestName(String guestName) { this.guestName = guestName; }
}