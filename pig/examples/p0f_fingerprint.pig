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

fingerprint_freq = GROUP fingerprints BY os;
summary = FOREACH fingerprint_freq GENERATE group, COUNT(fingerprints);
dump fingerprints;
--STORE summary INTO 'output/p0f_fingerprints';

