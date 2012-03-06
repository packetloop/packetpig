package com.packetloop.packetpig.loaders.pcap;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;
import org.apache.pig.data.Tuple;
import org.krakenapps.pcap.PcapInputStream;
import org.krakenapps.pcap.decoder.ethernet.EthernetDecoder;
import org.krakenapps.pcap.file.PcapFileInputStream;

import java.io.File;
import java.io.IOException;

public abstract class PcapRecordReader extends RecordReader<Long, Tuple> {
    protected long key;
    public EthernetDecoder eth;
    public Tuple tuple;
    protected String path;
    protected PcapInputStream is;

    @Override
    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        FileSplit fileSplit = (FileSplit)split;
        Path p = fileSplit.getPath();

        eth = new EthernetDecoder();

        if (p.toUri().getScheme().equals("file")) {
            path = p.toUri().getPath();
            is = new PcapFileInputStream(new File(path));
        } else {
            Configuration config = context.getConfiguration();
            FileSystem dfs = FileSystem.get(config);
            FSDataInputStream fsdis = dfs.open(p);
            path = p.toString();
            is = new PcapFSDataInputStream(fsdis);
        }
    }

    @Override
    public Long getCurrentKey() throws IOException, InterruptedException {
        return key;
    }

    @Override
    public Tuple getCurrentValue() throws IOException, InterruptedException {
        return tuple;
    }

    @Override
    public float getProgress() throws IOException, InterruptedException {
        return 0;
    }

    @Override
    public void close() throws IOException {
    }
}
