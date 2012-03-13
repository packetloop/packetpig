package com.packetloop.packetpig.loaders.pcap.protocol;

import com.packetloop.packetpig.loaders.pcap.StreamingPcapRecordReader;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.pig.data.Tuple;
import org.apache.pig.data.TupleFactory;

import java.io.BufferedReader;
import java.io.IOException;

public class HTTPConversationRecordReader extends StreamingPcapRecordReader {
    protected BufferedReader reader;
    private String field;
    private String pathToTcp;

    public HTTPConversationRecordReader(String pathToTcp, String field) {
        this.pathToTcp = pathToTcp;
        this.field = field;
    }

    @Override
    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        super.initialize(split, context);
        reader = streamingProcess(pathToTcp + " -r /dev/stdin -om http_headers -of tsv", path);
    }

    @Override
    public boolean nextKeyValue() throws IOException, InterruptedException {
        String line;
        boolean allFields = field == null || field.isEmpty();

        while ((line = reader.readLine()) != null) {
            String parts[] = line.split("\t");
            key = (long)Double.parseDouble(parts[0]);
            tuple = TupleFactory.getInstance().newTuple();

            // s, src, sport, dst, dport
            int i;
            for (i = 1; i < 5; i++)
                tuple.append(parts[i]);

            Tuple fields = null;
            if (allFields) {
                tuple.append(parts[i++]);
                fields = TupleFactory.getInstance().newTuple();
            }

            while (i > 0 && i < parts.length - 1) {
                if (allFields) {
                    fields.append(parts[i + 1]);
                } else if (parts[i].equals(field)) {
                    tuple.append(parts[i + 1]);
                    return true;
                }
                i++;
            }

            if (allFields) {
                tuple.append(fields);
                return true;
            }
        }

        return false;
    }
}
