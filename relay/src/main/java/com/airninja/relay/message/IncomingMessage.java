package com.airninja.relay.message;

public record IncomingMessage(String type, String deviceId, String to, String payload) {
}
