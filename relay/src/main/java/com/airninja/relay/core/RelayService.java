package com.airninja.relay.core;

import com.airninja.relay.message.DeliverMessage;
import com.airninja.relay.ws.ClientConnection;
import org.springframework.stereotype.Service;

@Service
public class RelayService {
    private final ConnectionRegistry registry;
    private final PendingMessageStore pendingMessages;

    public RelayService(ConnectionRegistry registry, PendingMessageStore pendingMessages) {
        this.registry = registry;
        this.pendingMessages = pendingMessages;
    }

    public void register(String deviceId, ClientConnection connection) {
        registry.register(deviceId, connection);
        pendingMessages.drain(deviceId).forEach(connection::send);
    }

    public void route(String fromDeviceId, String toDeviceId, String payload) {
        DeliverMessage message = DeliverMessage.of(fromDeviceId, payload);
        registry.find(toDeviceId).ifPresentOrElse(
            recipient -> recipient.send(message),
            () -> pendingMessages.enqueue(toDeviceId, message)
        );
    }

    public void disconnect(String deviceId, ClientConnection connection) {
        registry.unregister(deviceId, connection);
    }
}
