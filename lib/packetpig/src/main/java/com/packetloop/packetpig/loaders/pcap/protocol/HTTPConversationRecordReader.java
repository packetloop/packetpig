package com.packetloop.packetpig.loaders.pcap.protocol;

import com.packetloop.packetpig.loaders.pcap.PcapRecordReader;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.pig.data.TupleFactory;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class HTTPConversationRecordReader extends PcapRecordReader {
    protected BufferedReader reader;
    private String field;

    public HTTPConversationRecordReader(String field) {
        this.field = field;
    }

    @Override
    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        super.initialize(split, context);

        String cmd = "lib/scripts/tcp.py -r " + path + " -om http_headers -of tsv";

        ProcessBuilder builder = new ProcessBuilder(cmd.split(" "));
        //builder.redirectErrorStream(true);
        Process process = builder.start();

        reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
    }

    @Override
    public boolean nextKeyValue() throws IOException, InterruptedException {
        String line;

        while ((line = reader.readLine()) != null) {
            String parts[] = line.split("\t");
            key = (long)Double.parseDouble(parts[0]);
            tuple = TupleFactory.getInstance().newTuple();

            // s, src, sport, dst, dport
            int i;
            for (i = 1; i < 5; i++)
                tuple.append(parts[i]);

            while (i > 0 && i < parts.length) {
                if (parts[i].equals(field)) {
                    tuple.append(parts[i + 1]);
                    return true;
                }
                i++;
            }
        }

        return false;
    }
}
