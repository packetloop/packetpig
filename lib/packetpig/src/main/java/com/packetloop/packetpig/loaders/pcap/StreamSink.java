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
                System.err.print(stream.read());
            } catch (IOException ignored) {
            }
        }
    }
}
