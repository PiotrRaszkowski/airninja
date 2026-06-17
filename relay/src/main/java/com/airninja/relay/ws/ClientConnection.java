package com.airninja.relay.ws;

public interface ClientConnection {
    String id();

    void send(Object message);
}
