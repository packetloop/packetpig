package com.packetloop.packetpig.loaders.pcap.protocol;

import com.packetloop.packetpig.loaders.pcap.PcapRecordReader;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IOUtils;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.pig.data.TupleFactory;

import java.io.*;

public class HTTPConversationRecordReader extends PcapRecordReader {
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

        File out = File.createTempFile("prefix", "suffix");
        Configuration config = context.getConfiguration();
        FileSystem dfs = FileSystem.get(config);
        FSDataInputStream fsdis = dfs.open(new Path(path));

        String cmd = pathToTcp + " -r /dev/stdin -om http_headers -of tsv -o " + out.getPath();

        ProcessBuilder builder = new ProcessBuilder(cmd.split(" "));
        Process process = builder.start();
        OutputStream os = process.getOutputStream();
        IOUtils.copyBytes(fsdis, os, config);  // pipe from pcap stream into snort
        process.waitFor();

        reader = new BufferedReader(new FileReader(out));
        out.delete();
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
