package com.packetloop.packetpig.loaders.pcap;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.io.IOUtils;

import java.io.IOException;
import java.io.InputStream;

public class PcapStreamWriter implements Runnable {
    private Process process;
    private FSDataInputStream fsdis;
    private Configuration config;

    public PcapStreamWriter(Configuration config, Process process, FSDataInputStream fsdis) {
        this.process = process;
        this.fsdis = fsdis;
        this.config = config;
    }

    @Override
    public void run() {
        System.err.println("copying fsdis to process...");

        try {
            IOUtils.copyBytes(fsdis, process.getOutputStream(), config);
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
