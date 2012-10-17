package com.packetloop.packetpig.loaders.pcap.detection;

import com.packetloop.packetpig.loaders.pcap.StreamingPcapRecordReader;
import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.pig.data.TupleFactory;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class SnortRecordReader extends StreamingPcapRecordReader {
    private BufferedReader reader;
    private String configFile;
    private File logDir;

    public SnortRecordReader(String configFile) {
        this.configFile = configFile;
    }

    @Override
    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        super.initialize(split, context);

        logDir = File.createTempFile("prefix", "suffix");
        logDir.delete();
        logDir.mkdir();

        streamingProcess("snort -q -c " + configFile + " -A fast -y -l " + logDir + " -r -", path);
        process.waitFor();
        System.err.println("exit: " + process.exitValue());

        String logPath = logDir.getPath() + File.separatorChar + "alert";
        File logFile = new File(logPath);
        System.err.println(logPath + ": " + logFile.length() + " bytes");

        if (logFile.length() > 0) {
            reader = new BufferedReader(new FileReader(logFile));
            return;
        } else {
            reader = null;
            return;
        }
    }

    @Override
    public boolean nextKeyValue() throws IOException, InterruptedException {
        if (reader == null) {
            System.err.println("reader == null");
            return false;
        }

        String line;

        try {
            line = reader.readLine();
        } catch (IOException ignored) {
            System.err.println(IOException.class.getName());
            return false;
        }

        if (line == null) {
            System.err.println("line == null");
            return false;
        }

        // 11/30/11-20:23:31.674725  [**] [120:3:1] (http_inspect) NO CONTENT-LENGTH OR TRANSFER-ENCODING IN HTTP RESPONSE
        // [**] [Priority: 3] {TCP} 74.125.237.123:80 -> 192.168.0.19:42514
        // 11/30/11-20:23:31.426068  [**] [1:254:10] DNS SPOOF query response with TTL of 1 min. and no authority
        // [**] [Classification: Potentially Bad Traffic] [Priority: 2] {UDP} 192.168.0.1:53 -> 192.168.0.19:41229

        tuple = TupleFactory.getInstance().newTuple();

        Pattern p = Pattern.compile("([^ ]+)  [^ ]+ " +                 // ts
                "\\[(\\d+):(\\d+):(\\d+)\\] " +     // sig
                "(.*?) \\[\\*\\*\\].*?" +           // message
                "\\[Priority: ([\\d+])\\] " +       // priority
                "\\{([\\w+]+)\\} " +                // proto
                "([^:]+):*([^ ]*) -> " +            // src:sport
                "([^:]+):*([^ ]*)");                // dst:dport

        Matcher m = p.matcher(line);
        if (m.find()) {
            SimpleDateFormat formatter = new SimpleDateFormat("MM/dd/yy-HH:mm:ss.SSS");
            try {
                Date ts = formatter.parse(m.group(1));
                key = ts.getTime() / 1000;
            } catch (ParseException e) {
                e.printStackTrace();
                throw new IOException();
            }

            String[] sig_a = { m.group(2), m.group(3) };
            String sig = StringUtils.join(sig_a, "_");
            String message = m.group(5);
            int priority = Integer.parseInt(m.group(6));
            String proto = m.group(7);
            String src = m.group(8);

            int sport = 0;
            try {
                sport = Integer.parseInt(m.group(9));
            } catch (NumberFormatException ignored) {
                // nothing
            }

            String dst = m.group(10);
            int dport = 0;
            try {
                dport = Integer.parseInt(m.group(11));
            } catch (NumberFormatException ignored) {
                // nothing
            }

            tuple.append(sig);
            tuple.append(priority);
            tuple.append(message);
            tuple.append(proto);
            tuple.append(src);
            tuple.append(sport);
            tuple.append(dst);
            tuple.append(dport);

            return true;
        }

        return false;
    }

    @Override
    public void close() throws IOException {
        super.close();

        /*
        for (File f : logDir.listFiles())
            f.delete();

        logDir.delete();
        */

        if (reader != null)
            reader.close();
    }
}
