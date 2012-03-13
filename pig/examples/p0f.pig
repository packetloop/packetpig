%DEFAULT includepath pig/include.pig
RUN $includepath;

%DEFAULT snortconfig 'lib/snort/etc/snort.conf'

snort_alerts = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.detection.SnortLoader('$snortconfig') AS (
    ts:long,
    sig:chararray,
    priority:int,
    message:chararray,
    proto:chararray,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int
);

fingerprints = LOAD '$pcap' USING com.packetloop.packetpig.loaders.pcap.detection.FingerprintLoader() AS (
    ts:long,
    src:chararray,
    sport:int,
    dst:chararray,
    dport:int,
    os:chararray
);

attacker_fingerprints = JOIN
                            snort_alerts BY (src, sport, dst, dport),
                            fingerprints BY (src, sport, dst, dport);

DUMP attacker_fingerprints;
