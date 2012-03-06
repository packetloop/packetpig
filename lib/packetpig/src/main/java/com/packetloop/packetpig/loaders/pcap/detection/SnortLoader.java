package com.packetloop.packetpig.loaders.pcap.detection;

import com.packetloop.packetpig.loaders.pcap.PcapLoader;
import org.apache.hadoop.mapreduce.InputFormat;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.pig.data.Tuple;

import java.io.IOException;

public class SnortLoader extends PcapLoader {
    private String configFile = null;

    public SnortLoader() {
    }

    public SnortLoader(String configFile) {
        this.configFile = configFile;
    }

    @Override
    public InputFormat getInputFormat() throws IOException {
        return new FileInputFormat<Long, Tuple>() {
            @Override
            public RecordReader<Long, Tuple> createRecordReader(InputSplit split, TaskAttemptContext context) {
                return new SnortRecordReader(configFile);
            }
        };
    }
}
