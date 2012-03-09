package com.packetloop.packetpig.loaders.pcap.protocol;

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
import java.util.ArrayList;
import java.util.Iterator;

public class DNSConversationRecordReader extends PcapRecordReader {
    private BufferedReader reader;
    private static final ObjectMapper mapper = new ObjectMapper();
    private ArrayList<Tuple> tupleQueue;
    private int currentId;
    private String pathToDns;

    public DNSConversationRecordReader(String pathToDns) {
        this.pathToDns = pathToDns;
    }

    @Override
    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        super.initialize(split, context);

        Configuration config = context.getConfiguration();
        FileSystem dfs = FileSystem.get(config);
        FSDataInputStream fsdis = dfs.open(new Path(path));

        tupleQueue = new ArrayList<Tuple>();

        String cmd = pathToDns + " -r /dev/stdin";

        ProcessBuilder builder = new ProcessBuilder(cmd.split(" "));
        Process process = builder.start();
        OutputStream os = process.getOutputStream();
        IOUtils.copyBytes(fsdis, os, config);  // pipe from pcap stream into snort

        reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
    }

    private boolean getNextTuple() {
        if (tupleQueue.size() > 0) {
            tuple = tupleQueue.remove(0);
            return true;
        }
        return false;
    }

    @Override
    public boolean nextKeyValue() throws IOException, InterruptedException {
        if (getNextTuple())
            return true;

        while (true) {

            if (processNextLine() == false)
                return false;

            if (getNextTuple())
                return true;

        }
    }

    private boolean processNextLine() throws IOException {
        String line = reader.readLine();
        if (line == null)
            return false;

        Tuple t;
        JsonNode obj = mapper.readValue(line, JsonNode.class);

        key = obj.get("ts").getLongValue();
        currentId = obj.get("id").getIntValue();

        String mode = obj.get("mode").getTextValue();
        if ("query".equals(mode)) {
            Iterator<JsonNode> questions = obj.get("questions").getElements();
            while (questions.hasNext()) {
                JsonNode n = questions.next();
                t = TupleFactory.getInstance().newTuple();
                t.append(currentId);
                t.append(mode);
                t.append(n.get("qname").getTextValue());
                t.append(null);
                t.append(0);
                tupleQueue.add(t);
            }
        } else if (mode.equals("response")) {
            Iterator<JsonNode> answers = obj.get("answers").getElements();
            while (answers.hasNext()) {
                JsonNode n = answers.next();
                t = TupleFactory.getInstance().newTuple();
                t.append(currentId);
                t.append(mode);
                t.append(n.get("qname").getTextValue());
                t.append(getIpAddress(n));
                t.append(n.get("qttl").getLongValue());
                tupleQueue.add(t);
            }
        }
        return true;
    }

    private String getIpAddress(JsonNode n) {
        if (n.get("qrdata") == null)
            return null;
        if (n.get("qrdata").get("IPAddress") == null)
            return null;
        return n.get("qrdata").get("IPAddress").getTextValue();
    }
}
