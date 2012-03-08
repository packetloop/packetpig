package com.packetloop.packetpig.udf.geoip;

import com.maxmind.geoip.LookupService;
import org.apache.pig.EvalFunc;
import org.apache.pig.backend.executionengine.ExecException;
import org.apache.pig.data.Tuple;

import java.io.FileNotFoundException;
import java.io.IOException;

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
    public String exec(Tuple input) throws ExecException {
        return cl.getOrg((String)input.get(0));
    }
}
