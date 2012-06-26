package com.packetloop.packetpig.loaders.pcap;

import java.io.IOException;
import java.io.InputStream;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.io.IOUtils;

public class PcapStreamWriter implements Runnable {
    private Process process;
    private InputStream is;
    private Configuration config;

    public PcapStreamWriter(Configuration config, Process process, InputStream is) {
        this.process = process;
        this.is = is;
        this.config = config;
    }

    @Override
    public void run() {
        System.err.println("copying fsdis to process...");

        try {
            IOUtils.copyBytes(is, process.getOutputStream(), config);
        } catch (IOException ignored) {
            try {
                InputStream stderr = process.getErrorStream();
                if (stderr.available() > 0) {
                    byte[] msg = new byte[stderr.available()];
                    stderr.read(msg);
                    System.err.println(new String(msg));
                }
            } catch (IOException e) {
                System.err.println(e);
            }
        }

        System.err.println("fsdis copy done");
    }
}
