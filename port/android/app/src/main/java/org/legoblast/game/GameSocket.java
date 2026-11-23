package org.legoblast.game;

import java.net.URI;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.ArrayDeque;
import java.util.Arrays;

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.handshake.ServerHandshake;

public final class GameSocket extends WebSocketClient {
    private final ArrayDeque<byte[]> messages = new ArrayDeque<>();
    private int queuedBytes;

    GameSocket(String url) {
        super(URI.create(url));
        setConnectionLostTimeout(15);
    }

    @Override public void onOpen(ServerHandshake handshake) { enqueue(0, new byte[0]); }
    @Override public void onMessage(String text) { enqueue(1, text.getBytes(StandardCharsets.UTF_8)); }
    @Override public void onMessage(ByteBuffer bytes) {
        if (bytes.remaining() > 300000) { close(); return; }
        byte[] copy = new byte[bytes.remaining()];
        bytes.get(copy);
        enqueue(2, copy);
    }
    @Override public void onClose(int code, String reason, boolean remote) { enqueue(3, new byte[0]); }
    @Override public void onError(Exception error) { enqueue(3, new byte[0]); }

    private synchronized void enqueue(int event, byte[] payload) {
        if (queuedBytes + payload.length > 1500000) {
            messages.clear();
            queuedBytes = 0;
            messages.add(new byte[] {3});
            close();
            return;
        }
        byte[] message = Arrays.copyOf(payload, payload.length + 1);
        message[payload.length] = (byte)event;
        messages.add(message);
        queuedBytes += message.length;
    }

    public synchronized byte[] nextMessage() {
        byte[] message = messages.poll();
        if (message != null) queuedBytes -= message.length;
        return message;
    }

    public boolean sendMessage(byte[] bytes, boolean binary) {
        if (!isOpen()) return false;
        if (binary) send(bytes);
        else send(new String(bytes, StandardCharsets.UTF_8));
        return true;
    }

    public void stop() { close(); }
}
