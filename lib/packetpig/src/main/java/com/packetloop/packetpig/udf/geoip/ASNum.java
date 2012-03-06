package com.packetloop.packetpig.udf.geoip;

import com.maxmind.geoip.LookupService;
import org.apache.pig.EvalFunc;
import org.apache.pig.backend.executionengine.ExecException;
import org.apache.pig.data.Tuple;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class ASNum extends EvalFunc<String> {

    private LookupService cl;

    public ASNum() throws IOException {
        try {
            cl = new LookupService("data/GeoIPASNum.dat", LookupService.GEOIP_MEMORY_CACHE);
        } catch (FileNotFoundException ignored) {
            cl = new LookupService("GeoIPASNum.dat", LookupService.GEOIP_MEMORY_CACHE);
        }
    }

    @Override
    public List<String> getCacheFiles() {
        List<String> s = new ArrayList<String>();
        s.add("hdfs://" + System.getenv("HDFS_MASTER") + "/packetpig/GeoIPASNum.dat#GeoIPASNum.dat");
        return s;
    }
    @Override
    public String exec(Tuple input) throws ExecException {
        return cl.getOrg((String)input.get(0));
    }
}