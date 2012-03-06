package com.packetloop.packetpig.loaders.pcap;

import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.pig.LoadFunc;
import org.apache.pig.PigException;
import org.apache.pig.backend.executionengine.ExecException;
import org.apache.pig.backend.hadoop.executionengine.mapReduceLayer.PigSplit;
import org.apache.pig.data.Tuple;
import org.apache.pig.data.TupleFactory;

import java.io.IOException;
import java.util.ArrayList;

public abstract class PcapLoader extends LoadFunc {
    private TupleFactory tupleFactory = TupleFactory.getInstance();
    private ArrayList<Object> protoTuple = null;
    protected RecordReader in = null;

    protected PcapLoader() {
    }

    @Override
    public void setLocation(String location, Job job) throws IOException {
        FileInputFormat.setInputPaths(job, location);
        FileInputFormat.setMinInputSplitSize(job, 10L * 1024L * 1024L * 1024L * 1024L);
    }

   @Override
    public void prepareToRead(RecordReader reader, PigSplit split) throws IOException {
        in = reader;
    }

    @Override
    public Tuple getNext() throws IOException {
        // TODO not sure if protoTuple is necessary.
        if (protoTuple == null)
            protoTuple = new ArrayList<Object>();

        try {
            boolean anything = in.nextKeyValue();
            if (!anything)
                return null;

            Long key = (Long)in.getCurrentKey();
            protoTuple.add(key);

            Tuple values = (Tuple)in.getCurrentValue();
            for (Object obj : values.getAll())
                protoTuple.add(obj);

        } catch (InterruptedException e) {
            e.printStackTrace();
            int errCode = 6018;
            String errMsg = "Error while reading input";
            throw new ExecException(errMsg, errCode, PigException.REMOTE_ENVIRONMENT);
        }

        Tuple t = tupleFactory.newTupleNoCopy(protoTuple);
        protoTuple = null;

        return t;
    }
}
