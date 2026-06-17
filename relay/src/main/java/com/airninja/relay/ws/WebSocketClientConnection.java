package com.airninja.relay.ws;

import java.io.IOException;
import java.io.UncheckedIOException;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import tools.jackson.databind.ObjectMapper;

public class WebSocketClientConnection implements ClientConnection {
    private final WebSocketSession session;
    private final ObjectMapper objectMapper;

    public WebSocketClientConnection(WebSocketSession session, ObjectMapper objectMapper) {
        this.session = session;
        this.objectMapper = objectMapper;
    }

    @Override
    public String id() {
        return session.getId();
    }

    @Override
    public void send(Object message) {
        TextMessage textMessage = new TextMessage(objectMapper.writeValueAsString(message));
        try {
            synchronized (session) {
                session.sendMessage(textMessage);
            }
        } catch (IOException exception) {
            throw new UncheckedIOException("Failed to send relay message", exception);
        }
    }
}
