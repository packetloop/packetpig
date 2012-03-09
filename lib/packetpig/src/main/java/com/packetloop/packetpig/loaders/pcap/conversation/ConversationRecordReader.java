package com.packetloop.packetpig.loaders.pcap.conversation;

import com.packetloop.packetpig.loaders.pcap.PcapRecordReader;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IOUtils;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.pig.data.Tuple;
import org.apache.pig.data.TupleFactory;
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.map.ObjectMapper;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.util.Iterator;

public class ConversationRecordReader extends PcapRecordReader {
    protected BufferedReader reader;
    private static final ObjectMapper mapper = new ObjectMapper();
    protected String pathToTcp;

    public ConversationRecordReader(String pathToTcp) {
        this.pathToTcp = pathToTcp;
    }

    @Override
    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        super.initialize(split, context);

        Configuration config = context.getConfiguration();
        FileSystem dfs = FileSystem.get(config);
        FSDataInputStream fsdis = dfs.open(new Path(path));

        String cmd = pathToTcp + " -r " + path;

        ProcessBuilder builder = new ProcessBuilder(cmd.split(" "));
        Process process = builder.start();
        OutputStream os = process.getOutputStream();
        IOUtils.copyBytes(fsdis, os, config);  // pipe from pcap stream into snort

        reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
    }

    @Override
    public boolean nextKeyValue() throws IOException, InterruptedException {
        String line = reader.readLine();
        if (line == null)
            return false;

        tuple = TupleFactory.getInstance().newTuple();
        JsonNode obj = mapper.readValue(line, JsonNode.class);

        tuple.append(obj.get("src").getTextValue());
        tuple.append(obj.get("sport").getIntValue());
        tuple.append(obj.get("dst").getTextValue());
        tuple.append(obj.get("dport").getIntValue());
        tuple.append(obj.get("end_state").getTextValue());

        Tuple timestamps = TupleFactory.getInstance().newTuple();
        Tuple intervals = TupleFactory.getInstance().newTuple();
        Iterator<JsonNode> timestampNodes = obj.get("timestamps").getElements();

        double first = 0.0;

        while (timestampNodes.hasNext()) {
            double curr = timestampNodes.next().getDoubleValue();
            if (first == 0.0)
                first = curr;
            else
                intervals.append(curr - first);

            timestamps.append((long)curr);
        }

        tuple.append(timestamps);
        tuple.append(intervals);

        key = obj.get("ts").getLongValue();

        // TODO figure out if the process has ended.

        return true;
    }

    @Override
    public void close() throws IOException {
        super.close();
        reader.close();
    }
}
