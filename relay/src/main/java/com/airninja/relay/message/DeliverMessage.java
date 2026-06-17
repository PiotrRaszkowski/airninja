package com.airninja.relay.message;

public record DeliverMessage(String type, String from, String payload) {
    private static final String TYPE = "deliver";

    public static DeliverMessage of(String from, String payload) {
        return new DeliverMessage(TYPE, from, payload);
    }
}
