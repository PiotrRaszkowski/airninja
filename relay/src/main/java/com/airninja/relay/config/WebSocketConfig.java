package com.airninja.relay.config;

import com.airninja.relay.ws.RelayWebSocketHandler;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {
    private static final String RELAY_ENDPOINT = "/relay";

    private final RelayWebSocketHandler relayWebSocketHandler;

    public WebSocketConfig(RelayWebSocketHandler relayWebSocketHandler) {
        this.relayWebSocketHandler = relayWebSocketHandler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(relayWebSocketHandler, RELAY_ENDPOINT).setAllowedOrigins("*");
    }
}
