package com.airninja.relay.ws;

import com.airninja.relay.core.RelayService;
import com.airninja.relay.message.IncomingMessage;
import com.airninja.relay.message.ServerEvent;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import tools.jackson.databind.ObjectMapper;

@Component
public class RelayWebSocketHandler extends TextWebSocketHandler {
    private static final String ATTRIBUTE_CONNECTION = "connection";
    private static final String ATTRIBUTE_DEVICE_ID = "deviceId";

    private final RelayService relayService;
    private final ObjectMapper objectMapper;

    public RelayWebSocketHandler(RelayService relayService, ObjectMapper objectMapper) {
        this.relayService = relayService;
        this.objectMapper = objectMapper;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        session.getAttributes().put(ATTRIBUTE_CONNECTION, new WebSocketClientConnection(session, objectMapper));
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        IncomingMessage incoming = objectMapper.readValue(message.getPayload(), IncomingMessage.class);
        ClientConnection connection = connection(session);
        switch (incoming.type() == null ? "" : incoming.type()) {
            case "register" -> handleRegister(session, connection, incoming);
            case "send" -> handleSend(session, connection, incoming);
            default -> connection.send(ServerEvent.error("unknown message type: " + incoming.type()));
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        String deviceId = (String) session.getAttributes().get(ATTRIBUTE_DEVICE_ID);
        if (deviceId != null) {
            relayService.disconnect(deviceId, connection(session));
        }
    }

    private void handleRegister(WebSocketSession session, ClientConnection connection, IncomingMessage incoming) {
        String deviceId = incoming.deviceId();
        if (deviceId == null || deviceId.isEmpty()) {
            connection.send(ServerEvent.error("register requires a deviceId"));
            return;
        }
        session.getAttributes().put(ATTRIBUTE_DEVICE_ID, deviceId);
        relayService.register(deviceId, connection);
        connection.send(ServerEvent.registered(deviceId));
    }

    private void handleSend(WebSocketSession session, ClientConnection connection, IncomingMessage incoming) {
        String from = (String) session.getAttributes().get(ATTRIBUTE_DEVICE_ID);
        if (from == null) {
            connection.send(ServerEvent.error("register before sending"));
            return;
        }
        relayService.route(from, incoming.to(), incoming.payload());
    }

    private ClientConnection connection(WebSocketSession session) {
        return (ClientConnection) session.getAttributes().get(ATTRIBUTE_CONNECTION);
    }
}
