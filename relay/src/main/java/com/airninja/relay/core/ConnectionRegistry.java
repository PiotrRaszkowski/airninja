package com.airninja.relay.core;

import com.airninja.relay.ws.ClientConnection;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import org.springframework.stereotype.Component;

@Component
public class ConnectionRegistry {
    private final ConcurrentMap<String, ClientConnection> connections = new ConcurrentHashMap<>();

    public void register(String deviceId, ClientConnection connection) {
        connections.put(deviceId, connection);
    }

    public Optional<ClientConnection> find(String deviceId) {
        return Optional.ofNullable(connections.get(deviceId));
    }

    public void unregister(String deviceId, ClientConnection connection) {
        connections.remove(deviceId, connection);
    }

    public boolean isOnline(String deviceId) {
        return connections.containsKey(deviceId);
    }
}
