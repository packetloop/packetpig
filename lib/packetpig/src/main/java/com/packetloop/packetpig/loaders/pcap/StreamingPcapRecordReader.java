package com.packetloop.packetpig.loaders.pcap;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;

import java.io.*;

public abstract class StreamingPcapRecordReader extends PcapRecordReader {
    private TaskAttemptContext context;
    protected Thread thread;
    protected Process process;
    private long pos;
    private long len;
    private FSDataInputStream fsdis;

    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        super.initialize(split, context);
        this.context = context;
    }


    // TODO use a fifo and thread the piping and reading
    // TODO report actual progress
    protected void streamingProcess(String cmd, String path, boolean addOutput) throws IOException, InterruptedException {
        File out = File.createTempFile("packetpig", "stream");

        Configuration config = context.getConfiguration();
        FileSystem fs = FileSystem.get(config);
        Path dfsPath = new Path(path);

        fsdis = fs.open(dfsPath);
        len = fs.getLength(dfsPath);
        pos = 0;

        if (addOutput)
            cmd += out.getPath();

        System.err.println("streaming " + path + " to " + cmd);
        ProcessBuilder builder = new ProcessBuilder(cmd.split(" "));
        process = builder.start();

        // pipe from pcap stream into snort
        PcapStreamWriter writer = new PcapStreamWriter(config, process, fsdis);
        thread = new Thread(writer);
        thread.start();

        out.delete();
    }

    @Override
    public float getProgress() {
        try {
            pos = fsdis.getPos();
        } catch (IOException ignored) {
            pos = 0;
        }

        float progress = (float)pos / (float)len;
        System.err.println(pos + " / " + len + " = " + progress);
        return progress;
    }
}

