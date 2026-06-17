package com.airninja.relay.core;

import com.airninja.relay.message.DeliverMessage;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import org.springframework.stereotype.Component;

@Component
public class PendingMessageStore {
    private static final int MAX_PER_DEVICE = 100;

    private final ConcurrentMap<String, Deque<DeliverMessage>> pending = new ConcurrentHashMap<>();

    public void enqueue(String deviceId, DeliverMessage message) {
        pending.compute(deviceId, (key, queue) -> {
            Deque<DeliverMessage> target = queue == null ? new ArrayDeque<>() : queue;
            if (target.size() >= MAX_PER_DEVICE) {
                target.pollFirst();
            }
            target.addLast(message);
            return target;
        });
    }

    public List<DeliverMessage> drain(String deviceId) {
        Deque<DeliverMessage> queue = pending.remove(deviceId);
        return queue == null ? List.of() : new ArrayList<>(queue);
    }
}
