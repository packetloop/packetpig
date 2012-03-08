package com.packetloop.packetpig.udf.geoip;

import com.maxmind.geoip.LookupService;
import org.apache.pig.EvalFunc;
import org.apache.pig.backend.executionengine.ExecException;
import org.apache.pig.data.Tuple;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class Country extends EvalFunc<String> {

    private LookupService cl;

    public Country() throws IOException {
        try {
            cl = new LookupService("data/GeoIP.dat", LookupService.GEOIP_MEMORY_CACHE);
        } catch (FileNotFoundException ignored) {
            cl = new LookupService("GeoIP.dat", LookupService.GEOIP_MEMORY_CACHE);
        }
    }

    @Override
    public String exec(Tuple input) throws ExecException {
        return cl.getCountry((String)input.get(0)).getCode();
    }
}
