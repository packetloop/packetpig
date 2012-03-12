package com.packetloop.packetpig.loaders.pcap;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IOUtils;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;

import java.io.*;

public abstract class StreamingPcapRecordReader extends PcapRecordReader {
    private TaskAttemptContext context;

    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        super.initialize(split, context);
        this.context = context;
    }

    // TODO use a fifo and thread the piping and reading
    // TODO report actual progress
    protected BufferedReader streamingProcess(String cmd, String path, boolean addOutput) throws IOException, InterruptedException {
        File out = File.createTempFile("packetpig", "stream");
        Configuration config = context.getConfiguration();
        FileSystem dfs = FileSystem.get(config);
        FSDataInputStream fsdis = dfs.open(new Path(path));

        if (addOutput)
            cmd += out.getPath();

        ProcessBuilder builder = new ProcessBuilder(cmd.split(" "));
        Process process = builder.start();

        byte[] msg;
        InputStream stdin = process.getInputStream();
        OutputStream stdout = process.getOutputStream();
        InputStream stderr = process.getErrorStream();

        // pipe from pcap stream into snort
        try {
            IOUtils.copyBytes(fsdis, stdout, config);
        } catch (InterruptedIOException ignored) {
            msg = new byte[stderr.available()];
            stderr.read(msg);
            System.err.println(new String(msg));
        }

        process.waitFor();

        msg = new byte[stdin.available()];
        stdin.read(msg);
        System.err.println(new String(msg));

        BufferedReader reader = new BufferedReader(new FileReader(out));
        out.delete();

        return reader;
    }
}

