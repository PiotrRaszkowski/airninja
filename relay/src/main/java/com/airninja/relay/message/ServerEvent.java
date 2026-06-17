package com.airninja.relay.message;

public record ServerEvent(String type, String detail) {
    public static ServerEvent registered(String deviceId) {
        return new ServerEvent("registered", deviceId);
    }

    public static ServerEvent error(String message) {
        return new ServerEvent("error", message);
    }
}
