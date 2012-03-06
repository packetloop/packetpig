package com.packetloop.packetpig.loaders.pcap.detection;

import org.apache.pig.data.Tuple;
import org.apache.pig.data.TupleFactory;

public class FingerprintTuple {
    private Tuple tuple;
    private String title;
    private String os;
    private String app;
    private String dist;
    private String lang;
    private String link;
    private String params;
    private String raw_freq;
    private String raw_mtu;
    private Object raw_sig;
    private String uptime;

    public FingerprintTuple() {
        tuple = TupleFactory.getInstance().newTuple();
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public void addField(String k, String v) {
        if (k.equals("os"))
            os = v;

        if (k.equals("app"))
            app = v;

        if (k.equals("dist"))
            dist = v;

        if (k.equals("lang"))
            lang = v;

        if (k.equals("link"))
            link = v;

        if (k.equals("params"))
            params = v;

        if (k.equals("raw_freq"))
            raw_freq = v;

        if (k.equals("raw_mtu"))
            raw_mtu = v;

        if (k.equals("raw_sig"))
            raw_sig = v;

        if (k.equals("uptime"))
            uptime = v;
    }

    public void setSrc(String src) {
        tuple.append(src);
    }

    public void setSport(String sport) {
        tuple.append(sport);
    }

    public void setDst(String dst) {
        tuple.append(dst);
    }

    public void setDport(String dport) {
        tuple.append(dport);
    }

    public boolean anyGood() {
        return (os != null || app != null || dist != null || lang != null || link != null || params != null || raw_freq != null || raw_mtu != null || raw_sig != null || uptime != null);
    }

    public Tuple getTuple() {
        tuple.append(os);
        tuple.append(app);
        tuple.append(dist);
        tuple.append(lang);
        tuple.append(link);
        tuple.append(params);
        tuple.append(raw_freq);
        tuple.append(raw_mtu);
        tuple.append(raw_sig);
        tuple.append(uptime);

        return tuple;
    }
}
