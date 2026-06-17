package com.airninja.relay.ws;

import static java.util.concurrent.TimeUnit.SECONDS;
import static org.assertj.core.api.Assertions.assertThat;

import com.airninja.relay.message.DeliverMessage;
import com.airninja.relay.message.IncomingMessage;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import tools.jackson.databind.ObjectMapper;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class RelayWebSocketIntegrationTest {

    private final StandardWebSocketClient client = new StandardWebSocketClient();

    @Autowired
    private ObjectMapper objectMapper;

    @LocalServerPort
    private int port;

    @Test
    void routesEncryptedPayloadFromSenderToRegisteredRecipient() throws Exception {
        //GIVEN
        BlockingQueue<String> recipientMessages = new LinkedBlockingQueue<>();
        WebSocketSession recipient = connect(recipientMessages);
        register(recipient, "deviceB");
        awaitMessageOfType(recipientMessages, "registered");

        BlockingQueue<String> senderMessages = new LinkedBlockingQueue<>();
        WebSocketSession sender = connect(senderMessages);
        register(sender, "deviceA");
        awaitMessageOfType(senderMessages, "registered");

        //WHEN
        sender.sendMessage(new TextMessage(
            "{\"type\":\"send\",\"to\":\"deviceB\",\"payload\":\"ciphertext-xyz\"}"));

        //THEN
        DeliverMessage delivered = objectMapper.readValue(
            awaitMessageOfType(recipientMessages, "deliver"), DeliverMessage.class);
        assertThat(delivered.from()).isEqualTo("deviceA");
        assertThat(delivered.payload()).isEqualTo("ciphertext-xyz");

        sender.close();
        recipient.close();
    }

    private WebSocketSession connect(BlockingQueue<String> sink) throws Exception {
        TextWebSocketHandler handler = new TextWebSocketHandler() {
            @Override
            protected void handleTextMessage(WebSocketSession session, TextMessage message) {
                sink.add(message.getPayload());
            }
        };
        return client.execute(handler, "ws://localhost:" + port + "/relay").get(5, SECONDS);
    }

    private void register(WebSocketSession session, String deviceId) throws Exception {
        session.sendMessage(new TextMessage("{\"type\":\"register\",\"deviceId\":\"" + deviceId + "\"}"));
    }

    private String awaitMessageOfType(BlockingQueue<String> queue, String type) throws Exception {
        for (int attempt = 0; attempt < 10; attempt++) {
            String message = queue.poll(5, SECONDS);
            if (message == null) {
                break;
            }
            if (type.equals(objectMapper.readValue(message, IncomingMessage.class).type())) {
                return message;
            }
        }
        throw new AssertionError("did not receive message of type " + type);
    }
}
