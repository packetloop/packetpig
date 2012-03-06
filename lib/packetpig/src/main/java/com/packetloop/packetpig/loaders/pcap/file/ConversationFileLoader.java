package com.packetloop.packetpig.loaders.pcap.file;

import com.packetloop.packetpig.loaders.pcap.conversation.ConversationLoader;
import org.apache.hadoop.mapreduce.InputFormat;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.pig.data.Tuple;

import java.io.IOException;

public class ConversationFileLoader extends ConversationLoader {

    private String fileDumpPath;
    private String filter;

    public ConversationFileLoader(String pathToTcp, String fileDumpPath) {
        super(pathToTcp);
        this.fileDumpPath = fileDumpPath;
    }

    public ConversationFileLoader(String pathToTcp, String fileDumpPath, String filter) {
        super(pathToTcp);
        this.fileDumpPath = fileDumpPath;
        this.filter = filter;
    }

    @Override
    public InputFormat getInputFormat() throws IOException {
        return new FileInputFormat<Long, Tuple>() {
            @Override
            public RecordReader<Long, Tuple> createRecordReader(InputSplit split, TaskAttemptContext context) {
                return new ConversationFileRecordReader(pathToTcp, fileDumpPath, filter);
            }
        };
    }

}
