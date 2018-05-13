%DEFAULT includepath pig/include.pig
RUN $includepath;

fingerprints = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.detection.FingerprintLoader() AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    os:chararray,
    app:chararray,
    dist:chararray,
    lang:chararray,
    params:chararray,
    raw_freq:chararray,
    raw_mtu:chararray,
    raw_sig:chararray,
    uptime:chararray
);

connex = GROUP fingerprints BY src, flatten(os);
STORE connex INTO '$output/connex';
