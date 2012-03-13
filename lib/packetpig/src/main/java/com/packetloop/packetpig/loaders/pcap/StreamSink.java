package com.packetloop.packetpig.loaders.pcap;

import java.io.IOException;
import java.io.InputStream;

public class StreamSink implements Runnable {
    private InputStream stream;

    public StreamSink(InputStream stream) {
        this.stream = stream;
    }

    @Override
    public void run() {
        while (true) {
            try {
                byte[] msg = new byte[stream.available()];
                stream.read(msg);
                System.err.print(new String(msg));
            } catch (IOException ignored) {
            }
        }
    }
}
