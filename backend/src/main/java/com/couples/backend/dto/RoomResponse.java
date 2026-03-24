package com.couples.backend.dto;

public class RoomResponse {
    private String roomId;
    private String code;
    private String role;

    public RoomResponse(String roomId, String code, String role) {
        this.roomId = roomId;
        this.code = code;
        this.role = role;
    }

    public String getRoomId() { return roomId; }
    public void setRoomId(String roomId) { this.roomId = roomId; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
}