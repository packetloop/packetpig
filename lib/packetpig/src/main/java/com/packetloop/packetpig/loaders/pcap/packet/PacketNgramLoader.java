package com.packetloop.packetpig.loaders.pcap.packet;

import com.packetloop.packetpig.loaders.pcap.PcapLoader;
import org.apache.hadoop.mapreduce.InputFormat;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.pig.Expression;
import org.apache.pig.LoadMetadata;
import org.apache.pig.ResourceSchema;
import org.apache.pig.ResourceStatistics;
import org.apache.pig.ResourceSchema.ResourceFieldSchema;
import org.apache.pig.data.DataType;
import org.apache.pig.data.Tuple;

import java.io.IOException;

public class PacketNgramLoader extends PcapLoader implements LoadMetadata {
    private int n;
    private String filter;

    static final String[] NAMES = { 
        "key", "filter", "int_value", "count", 
    };
    
    static final Byte[] TYPES = { 
        DataType.LONG,    // "key"
        DataType.CHARARRAY, // "filter"
        DataType.INTEGER, // "int_value"
        DataType.INTEGER, // "count"
    };

    public PacketNgramLoader(String filter, String n) {
        this.filter = filter;
        this.n = Integer.parseInt(n);
    }

    @Override
    public InputFormat getInputFormat() throws IOException {
        return new FileInputFormat<Long, Tuple>() {
            @Override
            public RecordReader<Long, Tuple> createRecordReader(InputSplit split, TaskAttemptContext context) {
                return new PacketNgramRecordReader(filter, n);
            }
        };
    }

    @Override
    public ResourceSchema getSchema(String location, Job job) throws IOException {
        ResourceFieldSchema[] fields = new ResourceFieldSchema[NAMES.length];
        for (int i = 0; i < NAMES.length; i++) {
            ResourceFieldSchema field = new ResourceFieldSchema();
            field.setName(NAMES[i]);
            field.setType(TYPES[i]);
            fields[i] = field;
        }
        ResourceSchema schema = new ResourceSchema();
        schema.setFields(fields);
        return schema;
    }

    @Override
    public String[] getPartitionKeys(String location, Job job) throws IOException {
        return null;
    }

    @Override
    public ResourceStatistics getStatistics(String arg0, Job arg1) throws IOException {
        return null;
    }

    @Override
    public void setPartitionFilter(Expression arg0) throws IOException {
    }
}
