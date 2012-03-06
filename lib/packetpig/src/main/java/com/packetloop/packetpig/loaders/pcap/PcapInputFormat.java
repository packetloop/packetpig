package com.packetloop.packetpig.loaders.pcap;

import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;

import java.io.IOException;

public class PcapInputFormat extends FileInputFormat {
    // TODO split on tcp conversation boundary
    @Override
    public RecordReader createRecordReader(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        return null;
        //return new PcapRecordReader();
    }
}
