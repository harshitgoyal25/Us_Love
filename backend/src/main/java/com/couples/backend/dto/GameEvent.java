package com.couples.backend.dto;

import java.util.Map;

public class GameEvent {
    private String type;
    private String game;
    private Map<String, Object> payload;

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getGame() { return game; }
    public void setGame(String game) { this.game = game; }
    public Map<String, Object> getPayload() { return payload; }
    public void setPayload(Map<String, Object> payload) { this.payload = payload; }
}