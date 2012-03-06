package com.packetloop.packetpig.udf.util;

import org.apache.pig.EvalFunc;
import org.apache.pig.data.DataBag;
import org.apache.pig.data.DefaultDataBag;
import org.apache.pig.data.Tuple;
import org.apache.pig.data.TupleFactory;

import java.io.IOException;

public class Explode extends EvalFunc<DataBag> {
    @Override
    public DataBag exec(Tuple input) throws IOException {
        DataBag data = new DefaultDataBag();
        for (Object t_obj : input.getAll()) {
            Tuple tuple = (Tuple)t_obj;

            for (Object obj : tuple.getAll()) {
                Tuple t = TupleFactory.getInstance().newTuple();
                t.append(obj);
                data.add(t);
            }
        }

        return data;
    }
}
