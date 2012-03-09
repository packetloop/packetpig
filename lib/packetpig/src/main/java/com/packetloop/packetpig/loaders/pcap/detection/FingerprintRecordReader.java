package com.packetloop.packetpig.loaders.pcap.detection;

import com.packetloop.packetpig.loaders.pcap.PcapRecordReader;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IOUtils;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.TaskAttemptContext;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class FingerprintRecordReader extends PcapRecordReader {
    private BufferedReader reader;
    private ArrayList<FingerprintTuple> fingerprintArray = new ArrayList<FingerprintTuple>();
    private Iterator<FingerprintTuple> fingerprints;

    @Override
    public void initialize(InputSplit split, TaskAttemptContext context) throws IOException, InterruptedException {
        super.initialize(split, context);

        Configuration config = context.getConfiguration();
        FileSystem dfs = FileSystem.get(config);
        FSDataInputStream fsdis = dfs.open(new Path(path));

        String cmd = "p0f -r /dev/stdin";
        System.err.println(cmd);

        ProcessBuilder builder = new ProcessBuilder(cmd.split(" "));
        builder.redirectErrorStream(true);
        Process process = builder.start();

        OutputStream os = process.getOutputStream();
        IOUtils.copyBytes(fsdis, os, config);  // pipe from pcap stream into snort

        reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
    }

    @Override
    public boolean nextKeyValue() throws IOException, InterruptedException {
        /*
        .-[ 192.168.0.19/58121 -> 216.211.123.130/59214 (syn+ack) ]-
        | server   = 216.211.123.130/59214
        | os       = ???
        | dist     = 12
        | params   = none
        | raw_sig  = 4:52+12:0:1460:65535,1:mss,nop,ws,nop,nop,ts,sok,eol+1::0
        |
        `----
        */

        FingerprintTuple clientFingerprint = null;
        FingerprintTuple serverFingerprint = null;
        boolean clientMode = true;

        String line;
        while ((line = reader.readLine()) != null) {
            System.err.println(line);
            if (line.startsWith(".")) {
                Pattern p = Pattern.compile(" ([^/]+)/([0-9]+) -> ([^/]+)/([[0-9]]+)");
                Matcher m = p.matcher(line);
                m.find();

                if (clientFingerprint == null || !clientFingerprint.getTitle().equals(m.group(0))) {
                    if (clientFingerprint != null) {
                        if (clientFingerprint.anyGood())
                            fingerprintArray.add(clientFingerprint);

                        if (serverFingerprint.anyGood())
                            fingerprintArray.add(serverFingerprint);
                    }

                    clientFingerprint = new FingerprintTuple();
                    clientFingerprint.setTitle(m.group(0));
                    clientFingerprint.setSrc(m.group(1));
                    clientFingerprint.setSport(m.group(2));
                    clientFingerprint.setDst(m.group(3));
                    clientFingerprint.setDport(m.group(4));

                    serverFingerprint = new FingerprintTuple();
                    serverFingerprint.setTitle(m.group(0));
                    serverFingerprint.setSrc(m.group(3));
                    serverFingerprint.setSport(m.group(4));
                    serverFingerprint.setDst(m.group(1));
                    serverFingerprint.setDport(m.group(2));
                }
            }

            if (line.startsWith("| ")) {
                Pattern p = Pattern.compile("\\| (.*?) = (.*)");
                Matcher m = p.matcher(line);
                m.find();

                String k = m.group(1).trim();
                String v = m.group(2).trim();

                if (k.equals("client"))
                    clientMode = true;

                if (k.equals("server"))
                    clientMode = false;

                if (clientMode)
                    clientFingerprint.addField(k, v);
                else
                    serverFingerprint.addField(k, v);
            }
        }

        if (fingerprints == null)
            fingerprints = fingerprintArray.iterator();

        if (fingerprints.hasNext()) {
            tuple = fingerprints.next().getTuple();
            return true;
        }

        return false;
    }

    public static void main(String[] args) throws IOException {
        String cmd = "p0f -r /dev/stdin";
        ProcessBuilder builder = new ProcessBuilder(cmd.split(" "));
        Process process = builder.start();
    }
}
