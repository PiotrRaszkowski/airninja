package com.airninja.relay.core;

import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import com.airninja.relay.message.DeliverMessage;
import com.airninja.relay.ws.ClientConnection;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class RelayServiceTest {

    @Mock
    private ConnectionRegistry registry;

    @Mock
    private PendingMessageStore pendingMessages;

    @Mock
    private ClientConnection connection;

    @InjectMocks
    private RelayService relayService;

    @Test
    void registerWhenPendingMessagesExistThenRegistersAndDrainsToConnection() {
        //GIVEN
        DeliverMessage first = DeliverMessage.of("sender", "one");
        DeliverMessage second = DeliverMessage.of("sender", "two");
        given(pendingMessages.drain("deviceA")).willReturn(List.of(first, second));

        //WHEN
        relayService.register("deviceA", connection);

        //THEN
        verify(registry).register("deviceA", connection);
        verify(connection).send(first);
        verify(connection).send(second);
    }

    @Test
    void routeWhenRecipientOnlineThenSendsDeliverAndDoesNotEnqueue() {
        //GIVEN
        given(registry.find("deviceB")).willReturn(Optional.of(connection));

        //WHEN
        relayService.route("deviceA", "deviceB", "ciphertext");

        //THEN
        verify(connection).send(DeliverMessage.of("deviceA", "ciphertext"));
        verify(pendingMessages, never()).enqueue(org.mockito.ArgumentMatchers.anyString(), org.mockito.ArgumentMatchers.any());
    }

    @Test
    void routeWhenRecipientOfflineThenEnqueuesForLaterDelivery() {
        //GIVEN
        given(registry.find("deviceB")).willReturn(Optional.empty());

        //WHEN
        relayService.route("deviceA", "deviceB", "ciphertext");

        //THEN
        verify(pendingMessages).enqueue("deviceB", DeliverMessage.of("deviceA", "ciphertext"));
    }

    @Test
    void disconnectWhenCalledThenUnregistersConnection() {
        //WHEN
        relayService.disconnect("deviceA", connection);

        //THEN
        verify(registry).unregister("deviceA", connection);
    }
}
