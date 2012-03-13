package com.packetloop.packetpig.loaders.pcap.protocol;

import com.packetloop.packetpig.loaders.pcap.StreamingPcapRecordReader;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.pig.data.Tuple;
import org.apache.pig.data.TupleFactory;
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.map.ObjectMapper;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Iterator;

public class DNSConversationRecordReader extends StreamingPcapRecordReader {
    private BufferedReader reader;
    private static final ObjectMapper mapper = new ObjectMapper();
    private ArrayList<Tuple> tupleQueue;
    private String pathToDns;

    public DNSConversationRecordReader(String pathToDns) {
        this.pathToDns = pathToDns;
    }

    @Override
    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        super.initialize(split, context);
        tupleQueue = new ArrayList<Tuple>();
        streamingProcess(pathToDns + " -r /dev/stdin ", path, false);
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
        int currentId = obj.get("id").getIntValue();

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
