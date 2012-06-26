package com.packetloop.packetpig.loaders.pcap;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.compress.bzip2.CBZip2InputStream;
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
import java.util.zip.GZIPInputStream;

public abstract class PcapRecordReader extends RecordReader<Long, Tuple> {
    protected long key;
    public EthernetDecoder eth;
    public Tuple tuple;
    protected String path;
    protected PcapInputStream is;
    protected PcapFSDataInputStream fis;

    @Override
    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        FileSplit fileSplit = (FileSplit)split;
        Path p = fileSplit.getPath();

        eth = new EthernetDecoder();

        if (p.toUri().getScheme().equals("file")) {
            path = p.toUri().getPath();
            File file = new File(path);
            is = new PcapFileInputStream(file);
        } else {
            Configuration config = context.getConfiguration();
            FileSystem fs = FileSystem.get(config);
            FSDataInputStream fsdis = fs.open(p);
            path = p.toString();
            
            if(path.endsWith(".gz"))
            {
            	is = new PcapFSDataInputStream(new GZIPInputStream(fsdis), fs.getLength(p));
            }
            else if(path.endsWith(".bz") || path.endsWith(".bz2"))
            {
            	is = new PcapFSDataInputStream(new CBZip2InputStream(fsdis), fs.getLength(p));
            }
            else
            {
            	is = new PcapFSDataInputStream(fsdis, fs.getLength(p));
            }
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
    public float getProgress() {
        return 0.0f;
    }

    @Override
    public void close() throws IOException {
    }
}
