package com.packetloop.packetpig.loaders.pcap.detection;

import com.packetloop.packetpig.loaders.pcap.PcapLoader;
import org.apache.hadoop.mapreduce.InputFormat;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;

import java.io.IOException;

public class FingerprintLoader extends PcapLoader {
    @Override
    public InputFormat getInputFormat() throws IOException {
        return new FileInputFormat() {
            @Override
            public RecordReader createRecordReader(InputSplit split, TaskAttemptContext context) {
                return new FingerprintRecordReader();
            }
        };
    }
}
