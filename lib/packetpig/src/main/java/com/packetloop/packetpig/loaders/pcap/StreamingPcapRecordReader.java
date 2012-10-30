package com.packetloop.packetpig.loaders.pcap;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.compress.bzip2.CBZip2InputStream;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.zip.GZIPInputStream;

public abstract class StreamingPcapRecordReader extends PcapRecordReader {
    private TaskAttemptContext context;
    protected Thread thread;
    protected Process process;
    private InputStream is;

    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        super.initialize(split, context);
        this.context = context;
    }

    // TODO use a fifo and thread the piping and reading
    // TODO report actual progress
    protected BufferedReader streamingProcess(String cmd, String path) throws IOException, InterruptedException {
        Configuration config = context.getConfiguration();
        Path dfsPath = new Path(path);
        FileSystem fs = FileSystem.get(dfsPath.toUri(), config);

        is = fs.open(dfsPath);
        String name = dfsPath.getName().toLowerCase();
        if (name.endsWith(".gz")) {
            is = new GZIPInputStream(is);
        } else if (name.endsWith(".bz") || name.endsWith(".bz2")) {
            is = new CBZip2InputStream(is);
        }

        /*
        File out = File.createTempFile("packetpig", "stream");

        if (addOutput)
            cmd += out.getPath();

        out.delete();
        */

        System.err.println("streaming " + path + " to " + cmd);
        ProcessBuilder builder = new ProcessBuilder(cmd.split(" "));
        process = builder.start();

        // fuck stderr off
        ignore(process.getErrorStream());

        // pipe from pcap stream into snort
        PcapStreamWriter writer = new PcapStreamWriter(config, process, is);
        thread = new Thread(writer);
        thread.start();

        return new BufferedReader(new InputStreamReader(process.getInputStream()));
    }

    protected void ignore(InputStream errorStream) {
        StreamSink sink = new StreamSink(errorStream);
        new Thread(sink).start();
    }
}

