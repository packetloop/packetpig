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

public class PacketLoader extends PcapLoader implements LoadMetadata {
    
    static final String[] NAMES = { 
        "ts", 
        "ip_version", "ip_header_length", "ip_tos", "ip_total_length", 
        "ip_id", "ip_flags", "ip_frag_offset", "ip_ttl", "ip_proto", "ip_checksum", 
        "ip_src", "ip_dst", 
        "tcp_sport", "tcp_dport", "tcp_seq_id", "tcp_ack_id", 
        "tcp_offset", "tcp_ns", "tcp_cwr", "tcp_ece", "tcp_urg", "tcp_ack", "tcp_psh", 
        "tcp_rst", "tcp_syn", "tcp_fin", "tcp_window", "tcp_len", 
        "udp_sport", "udp_dport", "udp_len", "udp_checksum"
    };
    
    static final Byte[] TYPES = { 
        DataType.LONG, // "ts"
        DataType.INTEGER, // "ip_version"
        DataType.INTEGER, // "ip_header_length"
        DataType.INTEGER, // "ip_tos"
        DataType.INTEGER, // "ip_total_length"
        DataType.INTEGER, // "ip_id"
        DataType.INTEGER, // "ip_flags"
        DataType.INTEGER, // "ip_frag_offset"
        DataType.INTEGER, // "ip_ttl"
        DataType.INTEGER, // "ip_proto"
        DataType.INTEGER, // "ip_checksum"
        DataType.CHARARRAY, // "ip_src"
        DataType.CHARARRAY, // "ip_dst"
        DataType.INTEGER, // "tcp_sport"
        DataType.INTEGER, // "tcp_dport"
        DataType.LONG, // "tcp_seq_id"
        DataType.LONG, // "tcp_ack_id"
        DataType.INTEGER, // "tcp_offset"
        DataType.INTEGER, // "tcp_ns"
        DataType.INTEGER, // "tcp_cwr"
        DataType.INTEGER, // "tcp_ece"
        DataType.INTEGER, // "tcp_urg"
        DataType.INTEGER, // "tcp_ack"
        DataType.INTEGER, // "tcp_psh"
        DataType.INTEGER, // "tcp_rst"
        DataType.INTEGER, // "tcp_syn"
        DataType.INTEGER, // "tcp_fin"
        DataType.INTEGER, // "tcp_window"
        DataType.INTEGER, // "tcp_len"
        
        DataType.INTEGER, // "udp_sport"
        DataType.INTEGER, // "udp_dport"
        DataType.INTEGER, // "udp_len"
        DataType.CHARARRAY, // "udp_checksum"
    };
    
    @Override
    public InputFormat getInputFormat() throws IOException {
        return new FileInputFormat<Long, Tuple>() {
            @Override
            public RecordReader<Long, Tuple> createRecordReader(InputSplit split, TaskAttemptContext context) {
                return new PacketRecordReader();
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
